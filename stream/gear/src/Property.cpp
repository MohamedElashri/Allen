/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <Property.cuh>

void from_json(const nlohmann::json& j, dim3& d)
{
  const auto ar = j.get<std::array<unsigned, 3>>();
  d = {ar[0], ar[1], ar[2]};
}

void to_json(nlohmann::json& j, const dim3& d) { j = nlohmann::json {d.x, d.y, d.z}; }