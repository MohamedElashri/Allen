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

  nlohmann::json default_properties;

  // Loop over the algorithms, instantiate each algorithm and get its
  // (default valued) properties.
  for (auto alg : algorithms) {
    auto allen_alg = instantiate_allen_algorithm({alg, "algorithm", ""});
    default_properties[alg] = allen_alg.get_properties_infos();
  }
  std::cout << std::setw(4) << default_properties;
}
