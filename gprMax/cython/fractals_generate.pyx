# Copyright (C) 2015-2025: The University of Edinburgh, United Kingdom
#                 Authors: Craig Warren, Antonis Giannopoulos, and John Hartley
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

import numpy as np
cimport numpy as np
from cython.parallel import prange

from gprMax.config cimport float_or_double_complex


cpdef void generate_fractal2D(
    int nx,
    int ny,
    int ox,
    int oy,
    int gx,
    int gy,
    int nthreads,
    float D,
    np.float64_t[:] weighting,
    np.float64_t[:] v1,
    np.complex128_t[:, ::1] A,
    float_or_double_complex[:, ::1] fractalsurface
):
    """Generates a fractal surface for a 2D array.

    Args:
        nx, ny: int for fractal surface size in cells.
        nthreads: int for number of threads to use
        D: float for fractal dimension.
        weighting: memoryview for access to weighting vector.
        v1: memoryview for access to positional vector at centre of array,
            scaled by weighting.
        A: memoryview for access to array containing random numbers
            (to be convolved with fractal function).
        fractalsurface: memoryview for access to array containing fractal
                        surface data.
    """

    cdef Py_ssize_t i, j
    cdef double v2x, v2y, rr, B
    cdef int sx, sy

    sx = gx // 2
    sy = gy // 2

    for i in prange(nx, nogil=True, schedule='static', num_threads=nthreads):
        for j in range(ny):
                # Positional vector for current position
                v2x = weighting[0] * ((i + ox + sx) % gx)
                v2y = weighting[1] * ((j + oy + sy) % gy)

                # Calulate norm of v2 - v1
                rr = ((v2x - v1[0])**2 + (v2y - v1[1])**2)**(1/2)
                B = rr**D
                if B == 0:
                    B = 0.9

                fractalsurface[i, j] = A[i, j] / B


cpdef void generate_fractal3D(
    int nx,
    int ny,
    int nz,
    int ox,
    int oy,
    int oz,
    int gx,
    int gy,
    int gz,
    int nthreads,
    float D,
    np.float64_t[:] weighting,
    np.float64_t[:] v1,
    np.complex128_t[:, :, ::1] A,
    float_or_double_complex[:, :, ::1] fractalvolume
):
    """Generates a fractal volume for a 3D array.

    Args:
        nx, ny, nz: int for fractal volume size in cells.
        nthreads: int for number of threads to use
        D: float for fractal dimension.
        weighting: memoryview for access to weighting vector.
        v1: memoryview for access to positional vector at centre of array,
            scaled by weighting.
        A: memoryview for access to array containing random numbers
            (to be convolved with fractal function).
        fractalvolume: memoryview for access to array containing fractal
                        volume data.
    """

    cdef Py_ssize_t i, j, k
    cdef double v2x, v2y, v2z, rr, B
    cdef int sx, sy, sz

    sx = gx // 2
    sy = gy // 2
    sz = gz // 2

    for i in prange(nx, nogil=True, schedule='static', num_threads=nthreads):
        for j in range(ny):
            for k in range(nz):
                # Positional vector for current position
                v2x = weighting[0] * ((i + ox + sx) % gx)
                v2y = weighting[1] * ((j + oy + sy) % gy)
                v2z = weighting[2] * ((k + oz + sz) % gz)

                # Calulate norm of v2 - v1
                rr = ((v2x - v1[0])**2 + (v2y - v1[1])**2 + (v2z - v1[2])**2)**(1/2)
                B = rr**D
                if B == 0:
                    B = 0.9

                fractalvolume[i, j, k] = A[i, j, k] / B
