#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/iostream.h>

#include <map>
#include <string>
#include <iostream>
#include <numeric>
#include <cmath>

#include <Dumpers/IUpdater.h>
#include <Updater.h>
#include <Allen.h>

namespace {
  namespace py = pybind11;
  using std::map;
  using std::string;
}

inline int run(std::map<std::string, std::string> options, Allen::NonEventData::IUpdater* updater)
{
  return allen(options, updater);
}

// Python Module and Docstrings
PYBIND11_MODULE(PyAllen, m)
{
    m.doc() = R"pbdoc(
        Python entrypoint for Allen

        .. currentmodule:: Allen

        .. autosummary::
           :toctree: _generate

           PyAllen
    )pbdoc";

    py::class_<Allen::NonEventData::IUpdater>{m, "INonEventDataUpdater"};

    m.def("run", &run,
          py::call_guard<py::scoped_ostream_redirect,
                         py::scoped_estream_redirect>{},
          "Run Allen");

    m.def("make_updater", &make_updater,
          py::call_guard<py::scoped_ostream_redirect,
                         py::scoped_estream_redirect>{},
          "Make Updater");

}
