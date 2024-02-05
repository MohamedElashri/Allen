/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <tuple>
#include <vector>
#include <set>
#include <algorithm>
#include <cmath>
#include "Clustering.h"

void checkClustering(
  const std::vector<char>& geometry,
  const std::vector<char>& events,
  const std::vector<unsigned>& event_offsets,
  const std::vector<unsigned>& sizes_offsets,
  const std::vector<unsigned>& types_offsets,
  const std::vector<std::vector<uint32_t>>& found_clusters,
  float& reconstruction_efficiency,
  float& clone_fraction,
  float& ghost_fraction,
  const bool just_check_ids = true,
  const float allowed_distance_error = 1.f);
