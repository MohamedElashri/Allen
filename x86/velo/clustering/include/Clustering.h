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
  const bool assume_never_no_sp = false);

void cache_sp_patterns(unsigned char* sp_patterns, unsigned char* sp_sizes, float* sp_fx, float* sp_fy);
