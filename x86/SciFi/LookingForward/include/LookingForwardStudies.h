#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>

#include <cassert>

#include "Common.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "CpuHandler.cuh"
#include "SciFiEventModel.cuh"
#include "States.cuh"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "SciFiParametrization.h"
#include "TrackUtils.cuh"

#include "LookingForwardUtils.h"
#include "LookingForwardConstants.h"

#include "TMVA_Forward.cuh"
#include "TMVA_Forward_1.cuh"
#include "TMVA_Forward_2.cuh"

std::vector<std::vector<SciFi::TrackHits>> looking_forward_studies(
  const uint* host_scifi_hits,
  const uint* host_scifi_hit_count,
  const char* host_scifi_geometry,
  const std::array<float, 9>& host_inv_clus_res,
  const uint* host_velo_tracks_atomics,
  const uint* host_velo_track_hit_number,
  const char* host_velo_states,
  const int* host_atomics_ut,
  const uint* host_ut_track_hit_number,
  const float* host_ut_qop,
  const float* host_ut_x,
  const float* host_ut_tx,
  const float* host_ut_z,
  const uint* host_ut_track_velo_indices,
  const std::vector<std::vector<std::vector<uint32_t>>>& scifi_ids_ut_tracks,
  const std::vector<std::vector<float>>& p_events,
  const uint number_of_events,
  const SciFi::TrackHits* host_scifi_tracks,
  const int* host_atomics_scifi);
