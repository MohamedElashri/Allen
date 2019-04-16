#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/iostream.h>

#include <map>
#include <string>
#include <iostream>
#include <numeric>
#include <cmath>

#include <Allen.h>

namespace {
  namespace py = pybind11;
  using std::map;
  using std::string;
}

inline int run(std::map<std::string, std::string> options)
{
  return allen(options);
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

    m.def("run", &run,
          py::call_guard<py::scoped_ostream_redirect,
                         py::scoped_estream_redirect>{},
          "Run Allen");
}
