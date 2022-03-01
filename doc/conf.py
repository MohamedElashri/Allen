###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# This file is mainly copied from https://gitlab.cern.ch/lhcb/Moore/-/blob/master/doc/conf.py

import datetime
import os
import sys

sys.path.append(os.path.abspath("./_ext"))

# -- Project information -----------------------------------------------------

project = "Allen"
year = datetime.date.today().strftime("%Y")
copyright = f"2021-{year}, LHCb Collaboration"
author = "LHCb Collaboration"

# -- General configuration ---------------------------------------------------

master_doc = "index"

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "sphinx_rtd_theme",
    "sphinx.ext.autodoc",
    "sphinx.ext.napoleon",
    "sphinx.ext.viewcode",
    #"sphinx.ext.graphviz",
    "sphinx.ext.todo",
    #"graphviz_linked",
]

# Assume unmarked references (in backticks) refer to Python objects
default_role = "py:obj"

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = [
    "_*",
    "Thumbs.db",
    ".DS_Store",
]

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["_static"]

# Global file metadata
html_context = {
    "display_gitlab": True,
    "gitlab_host": "gitlab.cern.ch",
    "gitlab_user": "lhcb",
    "gitlab_repo": "Allen",
    "gitlab_version": "master/doc/",
}

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True

# If true, the current module name will be prepended to all description
# unit titles (such as .. function::).
add_module_names = False

# A list of regular expressions that match URIs that should not be
# checked when doing a linkcheck build.
linkcheck_ignore = [
    # egroup links will give 403
    r"https://groups\.cern\.ch/group/lhcb-rta-selections/default\.aspx",
    # really broken, see gaudi/Gaudi#156
    r"http://gaudi\.web\.cern\.ch/gaudi/doxygen/master/index\.html",
]
