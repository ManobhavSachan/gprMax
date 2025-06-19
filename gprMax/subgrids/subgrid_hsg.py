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

import gprMax.config as config

from ..cython.fields_updates_hsg import update_electric_os, update_is, update_magnetic_os
from .grid import SubGridBaseGrid

logger = logging.getLogger(__name__)


class SubGridHSG(SubGridBaseGrid):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def update_magnetic_is(self, precursors):
        """Updates the subgrid nodes at the IS with the currents derived
            from the main grid.

        Args:
            precursors:
        """

        # Form of FDTD update equations for H
        # Hz = c0Hz - c1Ey + c2Ex
        # Hy = c0Hy - c3Ex + c1Ez
        # Hx = c0Hx - c2Ez + c3Ey

        # Bottom and top
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwx,
            self.nwy + 1,
            self.nwz,
            1,
            self.Hy,
            precursors.ex_bottom,
            precursors.ex_top,
            self.IDlookup["Hy"],
            1,
            -1,
            3,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwx + 1,
            self.nwy,
            self.nwz,
            1,
            self.Hx,
            precursors.ey_bottom,
            precursors.ey_top,
            self.IDlookup["Hx"],
            -1,
            1,
            3,
            config.get_model_config().ompthreads,
        )

        # Left and right
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwy,
            self.nwz + 1,
            self.nwx,
            2,
            self.Hz,
            precursors.ey_left,
            precursors.ey_right,
            self.IDlookup["Hz"],
            1,
            -1,
            1,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwy + 1,
            self.nwz,
            self.nwx,
            2,
            self.Hy,
            precursors.ez_left,
            precursors.ez_right,
            self.IDlookup["Hy"],
            -1,
            1,
            1,
            config.get_model_config().ompthreads,
        )

        # Front and back
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwx,
            self.nwz + 1,
            self.nwy,
            3,
            self.Hz,
            precursors.ex_front,
            precursors.ex_back,
            self.IDlookup["Hz"],
            -1,
            1,
            2,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsH,
            self.ID,
            self.n_boundary_cells,
            -1,
            self.nwx + 1,
            self.nwz,
            self.nwy,
            3,
            self.Hx,
            precursors.ez_front,
            precursors.ez_back,
            self.IDlookup["Hx"],
            1,
            -1,
            2,
            config.get_model_config().ompthreads,
        )

    def update_electric_is(self, precursors):
        """Updates the subgrid nodes at the IS with the currents derived
            from the main grid.

        Args:
            precursors
        """

        # Form of FDTD update equations for E
        # Ex = c0(Ex) + c2(dHz) - c3(dHy)
        # Ey = c0(Ey) + c3(dHx) - c1(dHz)
        # Ez = c0(Ez) + c1(dHy) - c2(dHx)

        # Bottom and top
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwx,
            self.nwy + 1,
            self.nwz,
            1,
            self.Ex,
            precursors.hy_bottom,
            precursors.hy_top,
            self.IDlookup["Ex"],
            1,
            -1,
            3,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwx + 1,
            self.nwy,
            self.nwz,
            1,
            self.Ey,
            precursors.hx_bottom,
            precursors.hx_top,
            self.IDlookup["Ey"],
            -1,
            1,
            3,
            config.get_model_config().ompthreads,
        )

        # Left and right
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwy,
            self.nwz + 1,
            self.nwx,
            2,
            self.Ey,
            precursors.hz_left,
            precursors.hz_right,
            self.IDlookup["Ey"],
            1,
            -1,
            1,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwy + 1,
            self.nwz,
            self.nwx,
            2,
            self.Ez,
            precursors.hy_left,
            precursors.hy_right,
            self.IDlookup["Ez"],
            -1,
            1,
            1,
            config.get_model_config().ompthreads,
        )

        # Front and back
        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwx,
            self.nwz + 1,
            self.nwy,
            3,
            self.Ex,
            precursors.hz_front,
            precursors.hz_back,
            self.IDlookup["Ex"],
            -1,
            1,
            2,
            config.get_model_config().ompthreads,
        )

        update_is(
            self.nwx,
            self.nwy,
            self.nwz,
            self.updatecoeffsE,
            self.ID,
            self.n_boundary_cells,
            0,
            self.nwx + 1,
            self.nwz,
            self.nwy,
            3,
            self.Ez,
            precursors.hx_front,
            precursors.hx_back,
            self.IDlookup["Ez"],
            1,
            -1,
            2,
            config.get_model_config().ompthreads,
        )

    def update_electric_os(self, main_grid):
        """
        Args:
            main_grid: FDTDGrid class describing a grid in a model.
        """

        i_l = self.i0 - self.is_os_sep
        i_u = self.i1 + self.is_os_sep
        j_l = self.j0 - self.is_os_sep
        j_u = self.j1 + self.is_os_sep
        k_l = self.k0 - self.is_os_sep
        k_u = self.k1 + self.is_os_sep

        # Form of FDTD update equations for E
        # Ex = c0(Ex) + c2(dHz) - c3(dHy)
        # Ey = c0(Ey) + c3(dHx) - c1(dHz)
        # Ez = c0(Ez) + c1(dHy) - c2(dHx)

        # Front and back
        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            3,
            i_l,
            i_u,
            k_l,
            k_u + 1,
            j_l,
            j_u,
            self.nwy,
            main_grid.IDlookup["Ex"],
            main_grid.Ex,
            self.Hz,
            2,
            1,
            -1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            3,
            i_l,
            i_u + 1,
            k_l,
            k_u,
            j_l,
            j_u,
            self.nwy,
            main_grid.IDlookup["Ez"],
            main_grid.Ez,
            self.Hx,
            2,
            -1,
            1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        # Left and right
        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            2,
            j_l,
            j_u,
            k_l,
            k_u + 1,
            i_l,
            i_u,
            self.nwx,
            main_grid.IDlookup["Ey"],
            main_grid.Ey,
            self.Hz,
            1,
            -1,
            1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            2,
            j_l,
            j_u + 1,
            k_l,
            k_u,
            i_l,
            i_u,
            self.nwx,
            main_grid.IDlookup["Ez"],
            main_grid.Ez,
            self.Hy,
            1,
            1,
            -1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        # Bottom and top
        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            1,
            i_l,
            i_u,
            j_l,
            j_u + 1,
            k_l,
            k_u,
            self.nwz,
            main_grid.IDlookup["Ex"],
            main_grid.Ex,
            self.Hy,
            3,
            -1,
            1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_electric_os(
            main_grid.updatecoeffsE,
            main_grid.ID,
            1,
            i_l,
            i_u + 1,
            j_l,
            j_u,
            k_l,
            k_u,
            self.nwz,
            main_grid.IDlookup["Ey"],
            main_grid.Ey,
            self.Hx,
            3,
            1,
            -1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

    def update_magnetic_os(self, main_grid):
        """
        Args:
            main_grid: FDTDGrid class describing a grid in a model.
        """

        i_l = self.i0 - self.is_os_sep
        i_u = self.i1 + self.is_os_sep
        j_l = self.j0 - self.is_os_sep
        j_u = self.j1 + self.is_os_sep
        k_l = self.k0 - self.is_os_sep
        k_u = self.k1 + self.is_os_sep

        # Form of FDTD update equations for H
        # Hz = c0Hz - c1Ey + c2Ex
        # Hy = c0Hy - c3Ex + c1Ez
        # Hx = c0Hx - c2Ez + c3Ey

        # Front and back
        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            3,
            i_l,
            i_u,
            k_l,
            k_u + 1,
            j_l - 1,
            j_u,
            self.nwy,
            main_grid.IDlookup["Hz"],
            main_grid.Hz,
            self.Ex,
            2,
            1,
            -1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            3,
            i_l,
            i_u + 1,
            k_l,
            k_u,
            j_l - 1,
            j_u,
            self.nwy,
            main_grid.IDlookup["Hx"],
            main_grid.Hx,
            self.Ez,
            2,
            -1,
            1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        # Left and right
        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            2,
            j_l,
            j_u,
            k_l,
            k_u + 1,
            i_l - 1,
            i_u,
            self.nwx,
            main_grid.IDlookup["Hz"],
            main_grid.Hz,
            self.Ey,
            1,
            -1,
            1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            2,
            j_l,
            j_u + 1,
            k_l,
            k_u,
            i_l - 1,
            i_u,
            self.nwx,
            main_grid.IDlookup["Hy"],
            main_grid.Hy,
            self.Ez,
            1,
            1,
            -1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        # Bottom and top
        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            1,
            i_l,
            i_u,
            j_l,
            j_u + 1,
            k_l - 1,
            k_u,
            self.nwz,
            main_grid.IDlookup["Hy"],
            main_grid.Hy,
            self.Ex,
            3,
            -1,
            1,
            1,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

        update_magnetic_os(
            main_grid.updatecoeffsH,
            main_grid.ID,
            1,
            i_l,
            i_u + 1,
            j_l,
            j_u,
            k_l - 1,
            k_u,
            self.nwz,
            main_grid.IDlookup["Hx"],
            main_grid.Hx,
            self.Ey,
            3,
            1,
            -1,
            0,
            self.ratio,
            self.is_os_sep,
            self.n_boundary_cells,
            config.get_model_config().ompthreads,
        )

    def print_info(self):
        """Prints information about the subgrid.

        Useful info:
            Total region = working region +
                            2 * (is_os_sep * pml_separation * pml_thickness)
            is_os_sep: number of main grid cells between the Inner Surface and
                        the Outer Surface. Defaults to 3. Multiply by ratio to
                        get subgrid cells.
            pml_separation: number of subgrid cells between the Outer Surface
                            and the PML. Defaults to ratio // 2 + 2.
            pml_thickness: number of PML cells on each of the 6 sides of the
                            subgrid. Defaults to 6.
        """

        # Working region
        xs, ys, zs = self.round_to_grid(
            (
                self.i0 * self.dx * self.ratio,
                self.j0 * self.dy * self.ratio,
                self.k0 * self.dz * self.ratio,
            )
        )
        xf, yf, zf = self.round_to_grid(
            (
                self.i1 * self.dx * self.ratio,
                self.j1 * self.dy * self.ratio,
                self.k1 * self.dz * self.ratio,
            )
        )

        logger.info("")
        logger.debug(f"[{self.name}] Type: {self.__class__.__name__}")
        logger.info(f"[{self.name}] Ratio: 1:{self.ratio}")
        logger.info(
            f"[{self.name}] Spatial discretisation: {self.dx:g} x " + f"{self.dy:g} x {self.dz:g}m"
        )
        logger.info(
            f"[{self.name}] Extent (working region): {xs}m, {ys}m, {zs}m to {xf}m, {yf}m, {zf}m "
            + f"(({self.nwx} x {self.nwy} x {self.nwz} = {self.nwx * self.nwy * self.nwz} cells)"
        )
        logger.debug(
            f"[{self.name}] Total region: {self.nx:d} x {self.ny:d} x {self.nz:d} = "
            + f"{(self.nx * self.ny * self.nz):g} cells"
        )
        logger.info(f"[{self.name}] Time step: {self.dt:g} secs")
