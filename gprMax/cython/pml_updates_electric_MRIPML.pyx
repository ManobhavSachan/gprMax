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
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ey and Ez field components for the xminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float_or_double dx, dHy, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        IRA = 1 / RA[0, i]
        IRA1 = IRA - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RC0 = IRA * RB0 * RF0
        ii = xf - i
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHz - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHz -
                                    RC0 * Phi1[0, i, j, k])
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHy - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHy -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_xminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ey and Ez field components for the xminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float_or_double dx, dHy, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    cdef float_or_double RB1, RC1, RE1, RF1, Psi1, Psi2

    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        IRA = 1 / (RA[0, i] + RA[1, i])
        IRA1 = IRA - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RC0 = IRA * RF0
        RB1 = RB[1, i]
        RE1 = RE[1, i]
        RF1 = RF[1, i]
        RC1 = IRA * RF1
        ii = xf - i
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHz - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHz - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHz - Psi1)
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHy - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHy - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHy - Psi2)


cpdef void order1_xplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ey and Ez field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float_or_double dx, dHy, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        IRA = 1 / RA[0, i]
        IRA1 = IRA - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RC0 = IRA * RB0 * RF0
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHz - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHz  -
                                    RC0 * Phi1[0, i, j, k])
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHy - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHy -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_xplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ey and Ez field components for the xplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEy, materialEz
    cdef float_or_double dx, dHy, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    cdef float_or_double RB1, RC1, RE1, RF1, Psi1, Psi2
    dx = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        IRA = 1 / (RA[0, i] + RA[1, i])
        IRA1 = IRA - 1
        RB0 = RB[0, i]
        RE0 = RE[0, i]
        RF0 = RF[0, i]
        RC0 = IRA * RF0
        RB1 = RB[1, i]
        RE1 = RE[1, i]
        RF1 = RF[1, i]
        RC1 = IRA * RF1
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = k + zs
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii - 1, jj, kk]) / dx
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] - updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHz - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHz - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHz - Psi1)
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii - 1, jj, kk]) / dx
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] + updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHy - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHy - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHy - Psi2)


cpdef void order1_yminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ez field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float_or_double dy, dHx, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - j
            IRA = 1 / RA[0, j]
            IRA1 = IRA - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RC0 = IRA * RB0 * RF0
            for k in range(0, nz):
                kk = k + zs
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHz - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHz -
                                    RC0 * Phi1[0, i, j, k])
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHx - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHx -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_yminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ez field components for the yminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float_or_double dy, dHx, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    cdef float_or_double RB1, RC1, RE1, RF1, Psi1, Psi2
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = yf - j
            IRA = 1 / (RA[0, j] + RA[1, j])
            IRA1 = IRA - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RC0 = IRA * RF0
            RB1 = RB[1, j]
            RE1 = RE[1, j]
            RF1 = RF[1, j]
            RC1 = IRA * RF1
            for k in range(0, nz):
                kk = k + zs
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHz - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHz - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHz - Psi1)
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHx - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHx - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHx - Psi2)


cpdef void order1_yplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ez field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float_or_double dy, dHx, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            IRA = 1 / RA[0, j]
            IRA1 = IRA - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RC0 = IRA * RB0 * RF0
            for k in range(0, nz):
                kk = k + zs
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHz - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHz -
                                    RC0 * Phi1[0, i, j, k])
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHx - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHx -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_yplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ez field components for the yplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEz
    cdef float_or_double dy, dHx, dHz, IRA, IRA1, RB0, RC0, RE0, RF0
    cdef float_or_double RB1, RC1, RE1, RF1, Psi1, Psi2
    dy = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            IRA = 1 / (RA[0, j] + RA[1, j])
            IRA1 = IRA - 1
            RB0 = RB[0, j]
            RE0 = RE[0, j]
            RF0 = RF[0, j]
            RC0 = IRA * RF0
            RB1 = RB[1, j]
            RE1 = RE[1, j]
            RF1 = RF[1, j]
            RC1 = IRA * RF1
            for k in range(0, nz):
                kk = k + zs
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHz = (Hz[ii, jj, kk] - Hz[ii, jj - 1, kk]) / dy
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] + updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHz - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHz - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHz - Psi1)
                # Ez
                materialEz = ID[2, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj - 1, kk]) / dy
                Ez[ii, jj, kk] = (Ez[ii, jj, kk] - updatecoeffsE[materialEz, 4] *
                                  (IRA1 * dHx - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHx - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHx - Psi2)


cpdef void order1_zminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ey field components for the zminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float_or_double dz, dHx, dHy, IRA, IRA1, RB0, RC0, RE0, RF0
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - k
                IRA = 1 / RA[0, k]
                IRA1 = IRA - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RC0 = IRA * RB0 * RF0
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHy - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHy -
                                    RC0 * Phi1[0, i, j, k])
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHx - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHx -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_zminus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ey field components for the zminus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float_or_double dz, dHx, dHy, IRA, IRA1, RB0, RC0, RE0, RF0, RB1, RC1, RE1, RF1, Psi1, Psi2
    dz = d
    nx = xf - xs
    ny = yf - ys
    nz = zf - zs

    for i in prange(0, nx, nogil=True, schedule='static', num_threads=nthreads):
        ii = i + xs
        for j in range(0, ny):
            jj = j + ys
            for k in range(0, nz):
                kk = zf - k
                IRA = 1 / (RA[0, k] + RA[1, k])
                IRA1 = IRA - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RC0 = IRA * RF0
                RB1 = RB[1, k]
                RE1 = RE[1, k]
                RF1 = RF[1, k]
                RC1 = IRA * RF1
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHy - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHy - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHy - Psi1)
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHx - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHx - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHx - Psi2)


cpdef void order1_zplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ey field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float_or_double dz, dHx, dHy, IRA, IRA1, RB0, RC0, RE0, RF0
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
                IRA = 1 / RA[0, k]
                IRA1 = IRA - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RC0 = IRA * RB0 * RF0
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHy - IRA * Phi1[0, i, j, k]))
                Phi1[0, i, j, k] = (RE0 * Phi1[0, i, j, k] + RC0 * dHy -
                                    RC0 * Phi1[0, i, j, k])
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHx - IRA * Phi2[0, i, j, k]))
                Phi2[0, i, j, k] = (RE0 * Phi2[0, i, j, k] + RC0 * dHx -
                                    RC0 * Phi2[0, i, j, k])

cpdef void order2_zplus(
    int xs,
    int xf,
    int ys,
    int yf,
    int zs,
    int zf,
    int nthreads,
    float_or_double[:, ::1] updatecoeffsE,
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
    """Updates the Ex and Ey field components for the zplus slab.

    Args:
        xs, xf, ys, yf, zs, zf: ints for cell coordinates of PML slab.
        nthreads: int for number of threads to use.
        updatecoeffs, ID, E, H: memoryviews to access update coefficients,
                                ID and field component arrays.
        Phi, RA, RB, RE, RF: memoryviews to access PML coefficient arrays.
        d: float for spatial discretisation, e.g. dx, dy or dz.
    """

    cdef Py_ssize_t i, j, k, ii, jj, kk
    cdef int nx, ny, nz, materialEx, materialEy
    cdef float_or_double dz, dHx, dHy, IRA, IRA1, RB0, RC0, RE0, RF0
    cdef float_or_double RB1, RC1, RE1, RF1, Psi1, Psi2
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
                IRA = 1 / (RA[0, k] + RA[1, k])
                IRA1 = IRA - 1
                RB0 = RB[0, k]
                RE0 = RE[0, k]
                RF0 = RF[0, k]
                RC0 = IRA * RF0
                RB1 = RB[1, k]
                RE1 = RE[1, k]
                RF1 = RF[1, k]
                RC1 = IRA * RF1
                Psi1 = RB0 * Phi1[0, i, j, k] + RB1 * Phi1[1, i, j, k]
                Psi2 = RB0 * Phi2[0, i, j, k] + RB1 * Phi2[1, i, j, k]
                # Ex
                materialEx = ID[0, ii, jj, kk]
                dHy = (Hy[ii, jj, kk] - Hy[ii, jj, kk - 1]) / dz
                Ex[ii, jj, kk] = (Ex[ii, jj, kk] - updatecoeffsE[materialEx, 4] *
                                  (IRA1 * dHy - IRA * Psi1))
                Phi1[1, i, j, k] = RE1 * Phi1[1, i, j, k] + RC1 * (dHy - Psi1)
                Phi1[0, i, j, k] = RE0 * Phi1[0, i, j, k] + RC0 * (dHy - Psi1)
                # Ey
                materialEy = ID[1, ii, jj, kk]
                dHx = (Hx[ii, jj, kk] - Hx[ii, jj, kk - 1]) / dz
                Ey[ii, jj, kk] = (Ey[ii, jj, kk] + updatecoeffsE[materialEy, 4] *
                                  (IRA1 * dHx - IRA * Psi2))
                Phi2[1, i, j, k] = RE1 * Phi2[1, i, j, k] + RC1 * (dHx - Psi2)
                Phi2[0, i, j, k] = RE0 * Phi2[0, i, j, k] + RC0 * (dHx - Psi2)
