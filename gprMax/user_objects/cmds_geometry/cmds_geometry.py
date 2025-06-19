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
from scipy.spatial.transform import Rotation as R

import gprMax.config as config

logger = logging.getLogger(__name__)


def check_averaging(averaging):
    """Check and set material averaging value.

    Args:
        averaging: string for input value from hash command - should be 'y'
                    or 'n'.

    Returns:
        averaging: boolean for geometry object material averaging.
    """

    if averaging.lower() == "y":
        averaging = True
    elif averaging.lower() == "n":
        averaging = False
    else:
        logger.exception("Averaging should be either y or n")

    return averaging


def rotate_point(p, axis, angle, origin=(0, 0, 0)):
    """Rotates a point.

    Args:
        p: array of coordinates of point (x, y, z).
        axis: string which defines the axis about which to perform rotation (x, y, or z).
        angle: int specifying the angle of rotation (degrees).
        origin: tuple defining the point about which to perform rotation (x, y, z).

    Returns:
        p: array of coordinates of rotated point (x, y, z)
    """

    origin = np.array(origin)

    # Move point to axis of rotation
    p -= origin

    # Calculate rotation matrix
    r = R.from_euler(axis, angle, degrees=True)

    # Apply rotation
    p = r.apply(p)

    # Move object back to original axis
    p += origin

    return p


def rotate_2point_object(pts, axis, angle, origin=None):
    """Rotate a geometry object that is defined by 2 points.

    Args:
        pts: array ofcoordinates of points of object to be rotated.
        axis: string which defines the axis about which to perform rotation (x, y, or z).
        angle: int specifying the angle of rotation (degrees).
        origin: tuple defining the point about which to perform rotation (x, y, z).

    Returns:
        new_pts: array of coordinates of points of rotated object.
    """

    # Use origin at centre of object if not given
    if not origin:
        origin = pts[0, :] + (pts[1, :] - pts[0, :]) / 2

    # Check angle value is suitable
    angle = int(angle)
    if angle < 0 or angle > 360:
        logger.exception("Angle of rotation must be between 0-360 degrees")
        raise ValueError
    if angle % 90 != 0:
        logger.exception("Angle of rotation must be a multiple of 90 degrees")
        raise ValueError

    # Check axis is valid
    if axis not in ["x", "y", "z"]:
        logger.exception("Axis of rotation must be x, y, or z")
        raise ValueError

    # Save original points
    orig_pts = pts

    # Rotate points that define object
    pts[0, :] = rotate_point(pts[0, :], axis, angle, origin)
    pts[1, :] = rotate_point(pts[1, :], axis, angle, origin)

    # Get lower left and upper right coordinates to define new object
    new_pts = np.zeros(pts.shape)
    new_pts[0, :] = np.min(pts, axis=0)
    new_pts[1, :] = np.max(pts, axis=0)

    # Reset coordinates of invariant direction
    # - only needed for 2D models, has no effect on 3D models.
    if axis == "x":
        new_pts[0, 0] = orig_pts[0, 0]
        new_pts[1, 0] = orig_pts[1, 0]
    elif axis == "y":
        new_pts[0, 1] = orig_pts[0, 1]
        new_pts[1, 1] = orig_pts[1, 1]
    elif axis == "z":
        new_pts[0, 2] = orig_pts[0, 2]
        new_pts[1, 2] = orig_pts[1, 2]

    return new_pts


def rotate_polarisation(p, polarisation, axis, angle, G):
    """Rotates a geometry object that is defined by a point and polarisation.

    Args:
        p: array of coordinates of point (x, y, z).
        polarisation: string defining the current polarisation (x, y, or z).
        axis: string which defines the axis about which to perform rotation (x, y, or z).
        angle: int specifying the angle of rotation (degrees).
        G: FDTDGrid class describing a grid in a model.

    Returns:
        pts: array of coordinates of points of rotated object.
        new_polarisation: string defining the new polarisation (x, y, or z).
    """

    if polarisation.lower() == "x":
        new_pt = (p[0] + G.dx, p[1], p[2])
        if axis == "y" and angle == 90 or angle == 270:
            new_polarisation = "z"
        if axis == "z" and angle == 90 or angle == 270:
            new_polarisation = "y"

    elif polarisation.lower() == "y":
        new_pt = (p[0], p[1] + G.dy, p[2])
        if axis == "x" and angle == 90 or angle == 270:
            new_polarisation = "z"
        if axis == "z" and angle == 90 or angle == 270:
            new_polarisation = "x"

    elif polarisation.lower() == "z":
        new_pt = (p[0], p[1], p[2] + G.dz)
        if axis == "x" and angle == 90 or angle == 270:
            new_polarisation = "y"
        if axis == "y" and angle == 90 or angle == 270:
            new_polarisation = "x"

    pts = np.array([p, new_pt])

    return pts, new_polarisation
