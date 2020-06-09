#pragma once

#include <cmath>
#include <algorithm>
#include <map>
#include <string>
#include <vector>
#include <cfloat>
#include <cstdint>
#include "CudaCommon.h"
#include "Logger.h"
#include "ClusteringDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "CheckerTypes.h"

bool check_velopix_events(const std::vector<char>& events, const std::vector<uint>& event_offsets, size_t n_events);

std::map<std::string, float> calcResults(std::vector<float>& times);

std::vector<Checker::Tracks> read_forward_tracks(const char* events, const uint* event_offsets, const int n_events);
