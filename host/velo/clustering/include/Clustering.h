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

#include "Timer.h"
#include "Logger.h"
#include "ClusteringDefinitions.cuh"
#include "ClusteringCommon.h"
#include <cstring>

constexpr unsigned int max_cluster_size = 196608;

std::vector<std::vector<uint32_t>> clustering(
  const std::vector<char>& geometry,
  const std::vector<char>& events,
  const std::vector<unsigned int>& event_offsets,
  const std::vector<unsigned int>& event_sizes,
  const std::vector<unsigned int>& event_types,
  const bool assume_never_no_sp = false);

void cache_sp_patterns(unsigned char* sp_patterns, unsigned char* sp_sizes, float* sp_fx, float* sp_fy);
