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
#include <pybind11/pytypes.h>

#include <iostream>
#include <map>

#include <BankMapping.h>

namespace {
  namespace py = pybind11;

  std::map<std::string, std::set<std::string>> make_mapping()
  {
    std::map<std::string, std::set<std::string>> mapping;
    for (auto const& [lhcb_bt, bts] : Allen::bank_mapping) {
      std::set<std::string> to;
      for (auto bt : bts) {
        auto n = bank_name(bt);
        if (n == "Unknown") {
          throw StrException {"Cannot map BankType " + std::to_string(to_integral(bt)) +
                              " with unknown string representation"};
        }
        to.insert(n);
      }
      mapping.emplace(LHCb::RawBank::typeName(lhcb_bt), std::move(to));
    }
    return mapping;
  }
} // namespace

namespace Allen::Python {
  static const std::map<std::string, std::set<std::string>> mapping = make_mapping();
}

// Python Module and Docstrings
PYBIND11_MODULE(bank_mapping, m)
{
  m.doc() = R"pbdoc(
    Utility functions to obtain the mapping between HLT1 BankTypes and LHCb::RawBank::BankType

    .. currentmodule:: bank_mapping

    .. autosummary::
       :toctree: _generate

    bank_mapping
    )pbdoc";

  m.attr("mapping") = py::cast(&Allen::Python::mapping);
}
