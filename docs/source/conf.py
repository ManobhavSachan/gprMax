# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import re
import sys
import time

sys.path.insert(0, os.path.abspath("../.."))

project = "gprMax"
copyright = f'2015-{time.strftime("%Y")}, The University of Edinburgh, United Kingdom. Authors: Craig Warren, Antonis Giannopoulos, and John Hartley'
author = "Craig Warren, Antonis Giannopoulos, and John Hartley"
with open("../../gprMax/_version.py", "r") as fd:
    version = re.search(r'^__version__\s*=\s*[\'"]([^\'"]*)[\'"]', fd.read(), re.MULTILINE).group(1)

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.mathjax",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinx.ext.autosummary",
]

autodoc_mock_imports = [
    "h5py",
    "humanize",
    "mpi4py_fft",
    "mpi4py",
    "psutil",
    "terminaltables",
    "tqdm",
]

# Figure numbering
numfig = True

templates_path = ["_templates"]
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
html_static_path = ["_static"]
