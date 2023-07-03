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
#include <iostream>
#include <iomanip>
#include <iterator>
#include <string>
#include <algorithm>
#include <boost/algorithm/string.hpp>
#include <nlohmann/json.hpp>
#include <AlgorithmDB.h>

int main()
{
  // Read the semicolon-separated list of algorithms from stdin
  std::istreambuf_iterator<char> begin(std::cin), end;
  std::string input(begin, end);
  if (!input.empty() && input[input.size() - 1] == '\n') {
    input.erase(input.size() - 1);
  }

  // Split the list into algorithm namespace::type
  std::vector<std::string> algorithms;
  boost::split(algorithms, input, boost::is_any_of(";"));

  // Use non-default JSON parser to parse all floating point numbers
  // as floats and integers as 32 bits. This aligns with what is used
  // in Allen
  using json_float = nlohmann::basic_json<std::map, std::vector, std::string, bool, std::int32_t, std::uint32_t, float>;
  json_float default_properties;

  // Loop over the algorithms, instantiate each algorithm and get its
  // (default valued) properties.
  for (auto alg : algorithms) {
    auto allen_alg = instantiate_allen_algorithm({alg, "algorithm", ""});
    std::map<std::string, std::string> string_props;
    for (auto [k, j] : allen_alg.get_properties()) {
      // Assign to out JSON parser type to get the wanted parsing
      // behaviour and use to_string to allow the Python JSON parser
      // to change the values into Python objects.
      json_float jf = j;
      string_props[k] = to_string(jf);
    }
    // Save the representation in another JSON.
    default_properties[alg] = string_props;
  }
  std::cout << std::setw(4) << default_properties;
}
