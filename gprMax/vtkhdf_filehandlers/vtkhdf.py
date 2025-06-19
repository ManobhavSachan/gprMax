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
from abc import abstractmethod
from contextlib import AbstractContextManager
from enum import Enum
from os import PathLike
from pathlib import Path
from types import TracebackType
from typing import Optional, Tuple, Union

import h5py
import numpy as np
import numpy.typing as npt
from mpi4py.MPI import Intracomm

logger = logging.getLogger(__name__)


class VtkFileType(str, Enum):
    IMAGE_DATA = "ImageData"
    UNSTRUCTURED_GRID = "UnstructuredGrid"


class VtkHdfFile(AbstractContextManager):
    VERSION = [2, 2]
    FILE_EXTENSION = ".vtkhdf"
    ROOT_GROUP = "VTKHDF"

    # TODO: Can this be moved to using an Enum like root datasets?
    # Main barrier: Can't subclass an enum with members and any base
    # Enum class would need VERSION and TYPE as members.
    VERSION_ATTR = "Version"
    TYPE_ATTR = "Type"

    class Dataset(str, Enum):
        pass

    def __enter__(self):
        return self

    def __init__(
        self,
        filename: Union[str, PathLike],
        vtk_file_type: VtkFileType,
        mode: str = "r",
        comm: Optional[Intracomm] = None,
    ) -> None:
        """Create a new VtkHdfFile.

        If the file already exists, it will be overriden. Required
        attributes (Type and Version) will be written to the file.

        The file will be opened using the 'mpio' h5py driver if an MPI
        communicator is provided.

        Args:
            filename: Name of the file (can be a file path). The file
                extension will be set to '.vtkhdf'.
            mode (optional): Mode to open the file. Valid modes are
                - r Readonly, file must exist (default)
                - r+ Read/write, file must exist
                - w Create file, truncate if exists
                - w- or x Create file, fail if exists
                - a Read/write if exists, create otherwise
            comm (optional): MPI communicator containing all ranks that
                want to write to the file.

        """
        # Ensure the filename uses the correct extension
        self.filename = Path(filename)
        if self.filename.suffix != "" and self.filename.suffix != self.FILE_EXTENSION:
            logger.warning(
                f"Invalid file extension '{self.filename.suffix}' for VTKHDF file. Changing to '{self.FILE_EXTENSION}'."
            )

        self.filename = self.filename.with_suffix(self.FILE_EXTENSION)

        self.comm = comm

        # Check if the filehandler should use an MPI driver
        if self.comm is None:
            self.file_handler = h5py.File(self.filename, mode)
        else:
            self.file_handler = h5py.File(self.filename, mode, driver="mpio", comm=self.comm)

        logger.debug(f"Opened file '{self.filename}'")

        self.root_group = self.file_handler.require_group(self.ROOT_GROUP)

        # Set required Version and Type root attributes
        self._check_root_attribute(self.VERSION_ATTR, self.VERSION)

        type_as_ascii = vtk_file_type.encode("ascii")
        self._check_root_attribute(
            self.TYPE_ATTR, type_as_ascii, dtype=h5py.string_dtype("ascii", len(type_as_ascii))
        )

    def __exit__(
        self,
        exc_type: Optional[type[BaseException]],
        exc_value: Optional[BaseException],
        traceback: Optional[TracebackType],
    ) -> Optional[bool]:
        """Close the file when the context is exited.

        The parameters describe the exception that caused the context to
        be exited. If the context was exited without an exception, all
        three arguments will be None. Any exception will be
        processed normally upon exit from this method.

        Returns:
            suppress_exception (optional): Returns True if the exception
                should be suppressed (i.e. not propagated). Otherwise,
                the exception will be processed normally upon exit from
                this method.
        """
        self.close()

    def close(self) -> None:
        """Close the file handler"""
        logger.debug(f"Closed file '{self.filename}'")
        self.file_handler.close()

    def _check_root_attribute(
        self,
        attribute: str,
        expected_value: npt.ArrayLike,
        dtype: npt.DTypeLike = None,
    ):
        """Check root attribute is present and warn if not valid.

        If the attribute exists in the file that has been opened, the
        value will be checked against the expected value with a warning
        produced if they differ. If the attribute has not been set, it
        will be set to the expected value unless the file has been
        opened in readonly mode.

        Args:
            attribute: Name of the attribute.
            expected_value: Expected value of the attribute.
            dtype (optional): Data type of the attribute. Overrides
                expected_value.dtype if the attribute is set by
                this function.

        Returns:
            value: True if the attribute is present in the root VTKHDF
                group. False otherwise.
        """
        if self._has_root_attribute(attribute):
            value = self._get_root_attribute(attribute)
            if np.any(value != expected_value):
                logger.warning(
                    f"VTKHDF version mismatch. Expected '{expected_value}', but found '{value}'."
                )
        elif self.file_handler.mode == "r+":
            self._set_root_attribute(attribute, expected_value, dtype=dtype)
        else:
            logger.warning(f"Required VTKHDF attribute '{attribute}' not found.")

    def _has_root_attribute(self, attribute: str) -> bool:
        """Check if attribute is present in the root VTKHDF group.

        Args:
            attribute: Name of the attribute.

        Returns:
            value: True if the attribute is present in the root VTKHDF
                group. False otherwise.
        """
        value = self.root_group.attrs.get(attribute)
        return value is not None

    def _get_root_attribute(self, attribute: str) -> npt.NDArray:
        """Get attribute from the root VTKHDF group if it exists.

        Args:
            attribute: Name of the attribute.

        Returns:
            value: Current value of the attribute if it exists.

        Raises:
            KeyError: Raised if the attribute is not present as a key.
        """
        value = self.root_group.attrs.get(attribute)
        if value is None:
            raise KeyError(f"Attribute '{attribute}' not present in /{self.ROOT_GROUP} group")
        return value

    def _set_root_attribute(
        self, attribute: str, value: npt.ArrayLike, dtype: npt.DTypeLike = None
    ):
        """Set attribute in the root VTKHDF group.

        Args:
            attribute: Name of the new attribute.
            value: An array to initialize the attribute.
            dtype (optional): Data type of the attribute. Overrides
                value.dtype if both are given.
        """
        self.root_group.attrs.create(attribute, value, dtype=dtype)

    def _build_dataset_path(self, *path: str) -> str:
        """Build an HDF5 dataset path attached to the root VTKHDF group.

        Args:
            *path: Components of the required path.

        Returns:
            path: Path to the dataset.
        """
        return "/".join([self.ROOT_GROUP, *path])

    def _get_root_dataset(self, name: "VtkHdfFile.Dataset") -> h5py.Dataset:
        """Get specified dataset from the root group of the VTKHDF file.

        Args:
            path: Name of the dataset.

        Returns:
            dataset: Returns specified h5py dataset.
        """
        path = self._build_dataset_path(name)
        return self._get_dataset(path)

    def _get_dataset(self, path: str) -> h5py.Dataset:
        """Get specified dataset.

        Args:
            path: Absolute path to the dataset.

        Returns:
            dataset: Returns specified h5py dataset.

        Raises:
            KeyError: Raised if the dataset does not exist, or the path
                points to some other object, e.g. a Group not a Dataset.
        """
        cls = self.file_handler.get(path, getclass=True)
        if cls == "default":
            raise KeyError("Path does not exist")
        elif cls != h5py.Dataset:
            raise KeyError(f"Dataset not found. Found '{cls}' instead")

        dataset = self.file_handler.get(path)
        assert isinstance(dataset, h5py.Dataset)
        return dataset

    def _write_root_dataset(
        self,
        name: "VtkHdfFile.Dataset",
        data: npt.ArrayLike,
        shape: Optional[npt.NDArray[np.int32]] = None,
        offset: Optional[npt.NDArray[np.int32]] = None,
        xyz_data_ordering=True,
    ):
        """Write specified dataset to the root group of the VTKHDF file.

        Args:
            name: Name of the dataset.
            data: Data to initialize the dataset.
            shape (optional): Size of the full dataset being created.
                Can be omitted if data provides the full dataset.
            offset (optional): Offset to store the provided data at. Can
                be omitted if data provides the full dataset.
            xyz_data_ordering (optional): If True, the data will be
                transposed as VTKHDF stores datasets using ZYX ordering.
                Default True.
        """
        path = self._build_dataset_path(name)
        self._write_dataset(
            path, data, shape=shape, offset=offset, xyz_data_ordering=xyz_data_ordering
        )

    def _write_dataset(
        self,
        path: str,
        data: npt.ArrayLike,
        shape: Optional[Union[npt.NDArray[np.int32], Tuple[int, ...]]] = None,
        offset: Optional[npt.NDArray[np.int32]] = None,
        dtype: Optional[npt.DTypeLike] = None,
        xyz_data_ordering=True,
    ):
        """Write specified dataset to the VTKHDF file.

        If data has shape (d1, d2, ..., dn), i.e. n dimensions, then, if
        specified, shape and offset must be of length n.

        Args:
            path: Absolute path to the dataset.
            data: Data to initialize the dataset.
            shape (optional): Size of the full dataset being created.
                Can be omitted if data provides the full dataset.
            offset (optional): Offset to store the provided data at. Can
                be omitted if data provides the full dataset.
            dtype (optional): Type of the data. If omitted, the type
                will be deduced from the provided data.
            xyz_data_ordering (optional): If True, the data will be
                transposed as VTKHDF stores datasets using ZYX ordering.
                Default True.

        Raises:
            ValueError: Raised if the combination of data.shape, shape,
                and offset are invalid.
        """

        # Ensure data is a numpy array
        if not isinstance(data, np.ndarray):
            data = np.array(data, dtype=dtype)
            if data.ndim < 1:
                data = np.expand_dims(data, axis=-1)

        string_info = None

        # Warn if string data type will be converted from unicode to a
        # byte array (ascii). Only output a warning if the user
        # specified dtype
        if dtype is not None and np.dtype(dtype).kind == "U":
            logger.warning(
                "NumPy UTF-32 ('U' dtype) is not supported by HDF5."
                " Converting to bytes array ('S' dtype)."
            )

        # Ensure dtype is a numpy dtype
        if dtype is None:
            dtype = data.dtype
        elif isinstance(dtype, np.dtype):
            string_info = h5py.check_string_dtype(dtype)

            # Warn if user specified h5py string data type is invalid
            if string_info is not None and string_info.encoding == "utf-8":
                logger.warning(
                    "utf-8 encoding is not supported by VTKHDF. Converting to ascii encoding."
                )

            if string_info is not None and string_info.length is not None:
                if self.comm is None:
                    logger.warning(
                        "Fixed length strings are not supported by VTKHDF."
                        " Converting to variable length strings."
                    )
                else:
                    logger.warning(
                        "HDF5 does not support variable length strings with parallel I/O."
                        " Using fixed length strings instead."
                    )
                    logger.warning(
                        "VTKHDF does not support fixed length strings. File readers may generate"
                        " error messages when reading in a VTKHDF file containing fixed length"
                        " strings."
                    )
        else:
            dtype = np.dtype(dtype)

        # Explicitly define string datatype
        # VTKHDF only supports variable length ascii strings (not UTF-8)
        if dtype.kind == "U" or dtype.kind == "S" or string_info is not None:
            # If using parallel I/O, use fixed length strings
            length = None if self.comm is None else 0
            dtype = h5py.string_dtype(encoding="ascii", length=length)
            data = data.astype(dtype)

        # VTKHDF stores datasets using ZYX ordering rather than XYZ
        if xyz_data_ordering:
            data = data.transpose()

            if shape is not None:
                shape = np.flip(shape)

            if offset is not None:
                offset = np.flip(offset)

        logger.debug(
            f"Writing dataset '{path}', shape: {shape}, data.shape: {data.shape}, dtype: {dtype}"
        )

        if shape is None or all(shape == data.shape):
            shape = data.shape if shape is None else shape
            dataset = self.file_handler.create_dataset(path, shape=shape, dtype=dtype)
            dataset[:] = data
        elif offset is None:
            raise ValueError(
                "Offset must not be None as the full dataset has not been provided."
                " I.e. data.shape != shape"
            )
        else:
            dimensions = len(data.shape)

            if dimensions != len(shape):
                raise ValueError(
                    "The data and specified shape must have the same number of dimensions."
                    f" {dimensions} != {len(shape)}"
                )

            if dimensions != len(offset):
                raise ValueError(
                    "The data and specified offset must have the same number of dimensions."
                    f" {dimensions} != {len(offset)}"
                )

            if any(offset + data.shape > shape):
                raise ValueError(
                    "The provided offset and data does not fit within the bounds of the dataset."
                    f" {offset} + {data.shape} = {offset + data.shape} > {shape}"
                )

            dataset = self.file_handler.create_dataset(path, shape=shape, dtype=dtype)

            start = offset
            stop = offset + data.shape

            dataset_slice = tuple([slice(start[i], stop[i]) for i in range(dimensions)])

            dataset[dataset_slice] = data

    def _create_dataset(
        self, path: str, shape: Union[npt.NDArray[np.int32], Tuple[int, ...]], dtype: npt.DTypeLike
    ):
        """Create dataset in the VTKHDF file without writing any data.

        Args:
            path: Absolute path to the dataset.
            shape: Size of the full dataset being created.
            dtype: Type of the data.

        Raises:
            TypeError: Raised if attempt to use variable length strings
                with parallel I/O.
        """
        dtype = np.dtype(dtype)

        # If dtype is a string and using parallel I/O, ensure using
        # fixed length strings
        if self.comm is not None:
            string_info = h5py.check_string_dtype(dtype)
            if string_info is not None and string_info.length is None:
                raise TypeError(
                    "HDF5 does not support variable length strings with parallel I/O."
                    " Use a serial driver or fixed length strings instead."
                )

        string_info = h5py.check_string_dtype(dtype)

        if dtype.kind == "U":
            logger.warning(
                "NumPy UTF-32 ('U' dtype) is not supported by HDF5."
                " Converting to bytes array ('S' dtype)."
            )

        if string_info is not None and string_info.encoding == "utf-8":
            logger.warning(
                "utf-8 encoding is not supported by VTKHDF. Converting to ascii encoding."
            )

        # Explicitly define string datatype
        # VTKHDF only supports variable length ascii strings (not UTF-8)
        if (
            dtype.kind == "U"
            or dtype.kind == "S"
            or (string_info is not None and string_info.encoding == "utf-8")
        ):
            dtype = h5py.string_dtype(encoding="ascii", length=None)

        logger.debug(f"Creating dataset '{path}', shape: {shape}, dtype: {dtype}")

        self.file_handler.create_dataset(path, shape=shape, dtype=dtype)

    def _add_point_data(
        self,
        name: str,
        data: npt.NDArray,
        shape: Optional[Union[npt.NDArray[np.int32], Tuple[int, ...]]] = None,
        offset: Optional[npt.NDArray[np.int32]] = None,
    ):
        """Add point data to the VTKHDF file.

        Args:
            name: Name of the dataset.
            data: Data to be saved.
            shape (optional): Size of the full dataset being created.
                Can be omitted if data provides the full dataset.
            offset (optional): Offset to store the provided data at. Can
                be omitted if data provides the full dataset.
        """
        dataset_path = self._build_dataset_path("PointData", name)
        self._write_dataset(dataset_path, data, shape=shape, offset=offset)

    def _add_cell_data(
        self,
        name: str,
        data: npt.NDArray,
        shape: Optional[Union[npt.NDArray[np.int32], Tuple[int, ...]]] = None,
        offset: Optional[npt.NDArray[np.int32]] = None,
    ):
        """Add cell data to the VTKHDF file.

        Args:
            name: Name of the dataset.
            data: Data to be saved.
            shape (optional): Size of the full dataset being created.
                Can be omitted if data provides the full dataset.
            offset (optional): Offset to store the provided data at. Can
                be omitted if data provides the full dataset.
        """
        dataset_path = self._build_dataset_path("CellData", name)
        self._write_dataset(dataset_path, data, shape=shape, offset=offset)

    def add_field_data(
        self,
        name: str,
        data: Optional[npt.ArrayLike],
        shape: Optional[Union[npt.NDArray[np.int32], Tuple[int, ...]]] = None,
        offset: Optional[npt.NDArray[np.int32]] = None,
        dtype: Optional[npt.DTypeLike] = None,
    ):
        """Add field data to the VTKHDF file.

        Args:
            name: Name of the dataset.
            data: Data to be saved. Can be None if both shape and dtype
                are specified. If None, the dataset will be created but
                no data written. This can be useful if, for example,
                not all ranks are writing the data. As long as all ranks
                know the shape and dtype, ranks not writing data can
                perform the collective operation of creating the
                dataset, but only the rank(s) with the data need to
                write data.
            shape (optional): Size of the full dataset being created.
                Can be omitted if data provides the full dataset.
            offset (optional): Offset to store the provided data at. Can
                be omitted if data provides the full dataset.
            dtype (optional): Type of the data. If omitted, the type
                will be deduced from the provided data.
        """
        dataset_path = self._build_dataset_path("FieldData", name)
        if data is not None:
            self._write_dataset(
                dataset_path, data, shape=shape, offset=offset, dtype=dtype, xyz_data_ordering=False
            )
        elif shape is not None and dtype is not None:
            self._create_dataset(dataset_path, shape, dtype)
        else:
            raise ValueError(
                "If data is None, shape and dtype must be provided. I.e. they must not be None"
            )


class VtkCellType(np.uint8, Enum):
    """VTK cell types as defined here:
    https://vtk.org/doc/nightly/html/vtkCellType_8h_source.html#l00019
    """

    # Linear cells
    EMPTY_CELL = 0
    VERTEX = 1
    POLY_VERTEX = 2
    LINE = 3
    POLY_LINE = 4
    TRIANGLE = 5
    TRIANGLE_STRIP = 6
    POLYGON = 7
    PIXEL = 8
    QUAD = 9
    TETRA = 10
    VOXEL = 11
    HEXAHEDRON = 12
    WEDGE = 13
    PYRAMID = 14
    PENTAGONAL_PRISM = 15
    HEXAGONAL_PRISM = 16
