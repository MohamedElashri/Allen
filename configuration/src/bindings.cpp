/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/iostream.h>

#include <iostream>
#include <numeric>
#include <cmath>

#include <TCK.h>

namespace {
  namespace py = pybind11;
}

// Python Module and Docstrings
PYBIND11_MODULE(TCK, m)
{
  py::class_<LHCb::TCK::Info>(m, "TCKInfo")
    .def(py::init<>())
    .def_readwrite("digest", &LHCb::TCK::Info::digest)
    .def_readwrite("tck", &LHCb::TCK::Info::tck)
    .def_readwrite("release", &LHCb::TCK::Info::release)
    .def_readwrite("type", &LHCb::TCK::Info::type)
    .def_readwrite("label", &LHCb::TCK::Info::label)
    .def_readwrite("metadata", &LHCb::TCK::Info::metadata);

  m.doc() = R"pbdoc(
    Utility functions to interact with a git repository that contains
    persisted configurations identified by so-called TCK

    .. currentmodule:: TCK

    .. autosummary::
       :toctree: _generate

    TCKInfo
    tck_from_git
    sequence_to_git
    )pbdoc";

  m.attr("config_version") = py::int_(Allen::TCK::config_version);

  m.def("create_git_repository", &Allen::TCK::create_git_repository, "Create a git repository that can store TCKs");
  m.def("tck_from_git", &Allen::tck_from_git, "Get the TCK as it is in the git repository");
  m.def(
    "sequence_from_git",
    &Allen::sequence_from_git,
    "Get the TCK and TCK information in a format that can be used to "
    "configure Allen");
}
