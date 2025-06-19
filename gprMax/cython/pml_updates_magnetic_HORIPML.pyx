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

import numpy as np
cimport numpy as np
from cython.parallel import prange

from gprMax.config cimport float_or_double


cpdef void order1_xminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hy and Hz field components for the xminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float_or_double dx, dEy, dEz, RA01, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = xf - (i + 1)
        RA01 = RA[0, i] - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEy + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEy

cpdef void order2_xminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hy and Hz field components for the xminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float_or_double dx, dEy, dEz, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = xf - (i + 1)
        RA0 = RA[0, i]
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RA1 = RA[1, i]
        RB1 = RB[1, i]
        RE1 = RE[1, i]
        RF1 = RF[1, i]
        RA01 = RA[0, i] * RA[1, i] - 1
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEz + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEy + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEy + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEy


cpdef void order1_xplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hy and Hz field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float_or_double dx, dEy, dEz, RA01, RB0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        RA01 = RA[0, i] - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEy + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEy

cpdef void order2_xplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hy and Hz field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHy, materialHz
    cdef float_or_double dx, dEy, dEz, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        RA0 = RA[0, i]
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RA1 = RA[1, i]
        RB1 = RB[1, i]
        RE1 = RE[1, i]
        RF1 = RF[1, i]
        RA01 = RA[0, i] * RA[1, i] - 1
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEz = (Ez[ii + 1, jj, kk] - Ez[ii, jj, kk]) / dx
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] + updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEz + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEy = (Ey[ii + 1, jj, kk] - Ey[ii, jj, kk]) / dx
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] - updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEy + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEy + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEy


cpdef void order1_yminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hz field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float_or_double dy, dEx, dEz, RA01, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - (j + 1)
            RA01 = RA[0, j] - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx

cpdef void order2_yminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hz field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float_or_double dy, dEx, dEz, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - (j + 1)
            RA0 = RA[0, j]
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RA1 = RA[1, j]
            RB1 = RB[1, j]
            RE1 = RE[1, j]
            RF1 = RF[1, j]
            RA01 = RA[0, j] * RA[1, j] - 1
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEz + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEx + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx


cpdef void order1_yplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hz field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float_or_double dy, dEx, dEz, RA01, RB0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            RA01 = RA[0, j] - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx

cpdef void order2_yplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hz field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHz
    cdef float_or_double dy, dEx, dEz, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            RA0 = RA[0, j]
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RA1 = RA[1, j]
            RB1 = RB[1, j]
            RE1 = RE[1, j]
            RF1 = RF[1, j]
            RA01 = RA[0, j] * RA[1, j] - 1
            for k in range(0, nz):
                kk = k + zs
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEz = (Ez[ii, jj + 1, kk] - Ez[ii, jj, kk]) / dy
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] - updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEz + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEz + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEz
                # Hz
                materialHz = ID[5, ii, jj, kk]
                dEx = (Ex[ii, jj + 1, kk] - Ex[ii, jj, kk]) / dy
                Hz[ii, jj, kk] = (Hz[ii, jj, kk] + updatecoeffsH[materialHz, 4] *
                                  (RA01 * dEx + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx


cpdef void order1_zminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hy field components for the zminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float_or_double dz, dEx, dEy, RA01, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - (k + 1)
                RA01 = RA[0, k] - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEy + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx

cpdef void order2_zminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hy field components for the zminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float_or_double dz, dEx, dEy, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - (k + 1)
                RA0 = RA[0, k]
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RA1 = RA[1, k]
                RB1 = RB[1, k]
                RE1 = RE[1, k]
                RF1 = RF[1, k]
                RA01 = RA[0, k] * RA[1, k] - 1
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEy + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEy + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEx + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx


cpdef void order1_zplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hy field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float_or_double dz, dEx, dEy, RA01, RB0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                RA01 = RA[0, k] - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEy + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx

cpdef void order2_zplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsH,
    np.uint32_t[:, :, :, ::1] ID,
    float_or_double[:, :, ::1] Ex,
    float_or_double[:, :, ::1] Ey,
    float_or_double[:, :, ::1] Ez,
    float_or_double[:, :, ::1] Hx,
    float_or_double[:, :, ::1] Hy,
    float_or_double[:, :, ::1] Hz,
    float_or_double[:, :, :, ::1] Phi1,
    float_or_double[:, :, :, ::1] Phi2,
    float_or_double[:, ::1] RA,
    float_or_double[:, ::1] RB,
    float_or_double[:, ::1] RE,
    float_or_double[:, ::1] RF,
    float d
):
    """Updates the Hx and Hy field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialHx, materialHy
    cdef float_or_double dz, dEx, dEy, RA0, RA01, RB0, RE0, RF0, RA1, RB1, RE1, RF1
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                RA0 = RA[0, k]
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RA1 = RA[1, k]
                RB1 = RB[1, k]
                RE1 = RE[1, k]
                RF1 = RF[1, k]
                RA01 = RA[0, k] * RA[1, k] - 1
                # Hx
                materialHx = ID[3, ii, jj, kk]
                dEy = (Ey[ii, jj, kk + 1] - Ey[ii, jj, kk]) / dz
                Hx[ii, jj, kk] = (Hx[ii, jj, kk] + updatecoeffsH[materialHx, 4] *
                                  (RA01 * dEy + RA1 * RB0 * Phi1[0, i, j, k] +
                                  RB1 * Phi1[1, i, j, k]))
                Phi1[1, i, j, k] = (RE1 * Phi1[1, i, j, k] - RF1 *
                                    (RA0 * dEy + RB0 * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] - RF0 * dEy
                # Hy
                materialHy = ID[4, ii, jj, kk]
                dEx = (Ex[ii, jj, kk + 1] - Ex[ii, jj, kk]) / dz
                Hy[ii, jj, kk] = (Hy[ii, jj, kk] - updatecoeffsH[materialHy, 4] *
                                  (RA01 * dEx + RA1 * RB0 * Phi2[0, i, j, k] +
                                  RB1 * Phi2[1, i, j, k]))
                Phi2[1, i, j, k] = (RE1 * Phi2[1, i, j, k] - RF1 *
                                    (RA0 * dEx + RB0 * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] - RF0 * dEx
