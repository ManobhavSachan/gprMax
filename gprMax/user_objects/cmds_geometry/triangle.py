# Copyright (C) 2015-2025: The University of Edinburgh, United Kingdom
#                 Authors: Craig Warren, Antonis Giannopoulos, John Hartley, 
#                          and Nathan Mannall
#
# This file is part of gprMax.
#
# gprMax is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# gprMax is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with gprMax.  If not, see <http://www.gnu.org/licenses/>.

import logging

import numpy as np

from gprMax.cython.geometry_primitives import build_triangle
from gprMax.grid.fdtd_grid import FDTDGrid
from gprMax.materials import Material
from gprMax.user_objects.rotatable import RotatableMixin
from gprMax.user_objects.user_objects import GeometryUserObject

from .cmds_geometry import check_averaging, rotate_point

logger = logging.getLogger(__name__)


class Triangle(RotatableMixin, GeometryUserObject):
    """Introduces a triangular patch or a triangular prism with specific
        properties into the model.

    Attributes:
        p1: list of the coordinates (x,y,z) of the first apex of the triangle.
        p2: list of the coordinates (x,y,z) of the second apex of the triangle.
        p3: list of the coordinates (x,y,z) of the third apex of the triangle.
        thickness: float for the thickness of the triangular prism. If the
                    thickness is zero then a triangular patch is created.
        material_id: string for the material identifier that must correspond
                        to material that has already been defined.
        material_ids: list of material identifiers in the x, y, z directions.
        averaging: string (y or n) used to switch on and off dielectric smoothing.
    """

    @property
    def hash(self):
        return "#triangle"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def _do_rotate(self, grid: FDTDGrid):
        """Performs rotation."""
        p1 = rotate_point(self.kwargs["p1"], self.axis, self.angle, self.origin)
        p2 = rotate_point(self.kwargs["p2"], self.axis, self.angle, self.origin)
        p3 = rotate_point(self.kwargs["p3"], self.axis, self.angle, self.origin)
        self.kwargs["p1"] = tuple(p1)
        self.kwargs["p2"] = tuple(p2)
        self.kwargs["p3"] = tuple(p3)

    def build(self, grid: FDTDGrid):
        try:
            up1 = self.kwargs["p1"]
            up2 = self.kwargs["p2"]
            up3 = self.kwargs["p3"]
            thickness = self.kwargs["thickness"]
        except KeyError:
            logger.exception(f"{self.__str__()} specify 3 points and a thickness")
            raise

        if self.do_rotate:
            self._do_rotate(grid)

        # Check averaging
        try:
            # Try user-specified averaging
            averagetriangularprism = check_averaging(self.kwargs["averaging"])
        except KeyError:
            # Otherwise go with the grid default
            averagetriangularprism = grid.averagevolumeobjects

        # Check materials have been specified
        # Isotropic case
        try:
            materialsrequested = [self.kwargs["material_id"]]
        except KeyError:
            # Anisotropic case
            try:
                materialsrequested = self.kwargs["material_ids"]
            except KeyError:
                logger.exception(f"{self.__str__()} no materials have been specified")
                raise

        uip = self._create_uip(grid)

        # Check whether points are valid against grid
        dp1, dp2, dp3 = uip.check_tri_points(up1, up2, up3, self.__str__())
        # Convert points to metres
        x1, y1, z1 = uip.discrete_to_continuous(dp1)
        x2, y2, z2 = uip.discrete_to_continuous(dp2)
        x3, y3, z3 = uip.discrete_to_continuous(dp3)

        # Check for valid orientations
        # yz-plane triangle
        if x1 == x2 == x3:
            normal = "x"
            lower_extent = up1[0]
        # xz-plane triangle
        elif y1 == y2 == y3:
            normal = "y"
            lower_extent = up1[1]
        # xy-plane triangle
        elif z1 == z2 == z3:
            normal = "z"
            lower_extent = up1[2]
        else:
            logger.exception(f"{self.__str__()} the triangle is not specified correctly")
            raise ValueError

        triangle_within_grid, lower_extent, thickness = uip.check_thickness(
            normal, lower_extent, thickness, self.__str__()
        )

        # Exit early if none of the triangle is in this grid as there is
        # nothing else to do.
        if not triangle_within_grid:
            return

        # Update start bound of the triangle
        # yz-plane triangle
        if normal == "x":
            x1 = x2 = x3 = lower_extent
        # xz-plane triangle
        elif normal == "y":
            y1 = y2 = y3 = lower_extent
        # xy-plane triangle
        elif normal == "z":
            z1 = z2 = z3 = lower_extent

        # Look up requested materials in existing list of material instances
        materials = [y for x in materialsrequested for y in grid.materials if y.ID == x]

        if len(materials) != len(materialsrequested):
            notfound = [x for x in materialsrequested if x not in materials]
            logger.exception(f"{self.__str__()} material(s) {notfound} do not exist")
            raise ValueError

        if thickness > 0:
            # Isotropic case
            if len(materials) == 1:
                averaging = materials[0].averagable and averagetriangularprism
                numID = numIDx = numIDy = numIDz = materials[0].numID

            # Uniaxial anisotropic case
            elif len(materials) == 3:
                averaging = False
                numIDx = materials[0].numID
                numIDy = materials[1].numID
                numIDz = materials[2].numID
                requiredID = Material.create_compound_id(materials[0], materials[1], materials[2])
                averagedmaterial = [x for x in grid.materials if x.ID == requiredID]
                if averagedmaterial:
                    numID = averagedmaterial.numID
                else:
                    numID = len(grid.materials)
                    m = Material(numID, requiredID)
                    m.type = "dielectric-smoothed"
                    # Create dielectric-smoothed constituents for material
                    m.er = np.mean((materials[0].er, materials[1].er, materials[2].er), axis=0)
                    m.se = np.mean((materials[0].se, materials[1].se, materials[2].se), axis=0)
                    m.mr = np.mean((materials[0].mr, materials[1].mr, materials[2].mr), axis=0)
                    m.sm = np.mean((materials[0].sm, materials[1].sm, materials[2].sm), axis=0)

                    # Append the new material object to the materials list
                    grid.materials.append(m)
        else:
            averaging = False
            # Isotropic case
            if len(materials) == 1:
                numID = numIDx = numIDy = numIDz = materials[0].numID

            # Uniaxial anisotropic case
            elif len(materials) == 3:
                # numID requires a value but it will not be used
                numID = None
                numIDx = materials[0].numID
                numIDy = materials[1].numID
                numIDz = materials[2].numID

        build_triangle(
            x1,
            y1,
            z1,
            x2,
            y2,
            z2,
            x3,
            y3,
            z3,
            normal,
            thickness,
            grid.dx,
            grid.dy,
            grid.dz,
            numID,
            numIDx,
            numIDy,
            numIDz,
            averaging,
            grid.solid,
            grid.rigidE,
            grid.rigidH,
            grid.ID,
        )

        p4 = uip.round_to_grid_static_point(up1)
        p5 = uip.round_to_grid_static_point(up2)
        p6 = uip.round_to_grid_static_point(up3)

        if thickness > 0:
            dielectricsmoothing = "on" if averaging else "off"
            logger.info(
                f"{self.grid_name(grid)}Triangle with coordinates "
                f"{p4[0]:g}m {p4[1]:g}m {p4[2]:g}m, {p5[0]:g}m {p5[1]:g}m "
                f"{p5[2]:g}m, {p6[0]:g}m {p6[1]:g}m {p6[2]:g}m and thickness "
                f"{thickness:g}m of material(s) {', '.join(materialsrequested)} "
                f"created, dielectric smoothing is {dielectricsmoothing}."
            )
        else:
            logger.info(
                f"{self.grid_name(grid)}Triangle with coordinates "
                f"{p4[0]:g}m {p4[1]:g}m {p4[2]:g}m, {p5[0]:g}m {p5[1]:g}m "
                f"{p5[2]:g}m, {p6[0]:g}m {p6[1]:g}m {p6[2]:g}m of material(s) "
                f"{', '.join(materialsrequested)} created."
            )
