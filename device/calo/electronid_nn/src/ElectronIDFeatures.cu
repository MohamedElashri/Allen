/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ElectronIDFeatures.cuh"
#include <cmath>
#include <cwchar>

INSTANTIATE_ALGORITHM(electronid_features::electronid_features_t)

void electronid_features::electronid_features_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_electronid_features_t>(arguments, 7 * first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void electronid_features::electronid_features_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{

  global_function(electronid_features)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_electronid_mva_min_rescales, constants.dev_electronid_mva_max_rescales);
}

__global__ void electronid_features::electronid_features(
  electronid_features::Parameters parameters,
  const float* min_rescales,
  const float* max_rescales)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  constexpr int input_size = 7;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;
    float* electron_id_features = parameters.dev_electronid_features + input_size * scifi_idx_with_offset;
    float logdb = logf(max(fabsf(parameters.dev_delta_barycenter[scifi_idx_with_offset]), 1e-10f));
    float logdx = logf(max(fabsf(parameters.dev_dispersion_x[scifi_idx_with_offset]), 1e-10f));
    float logdy = logf(max(fabsf(parameters.dev_dispersion_y[scifi_idx_with_offset]), 1e-10f));
    float logdxy = logf(max(fabsf(parameters.dev_dispersion_xy[scifi_idx_with_offset]), 1e-10f));
    electron_id_features[0] =
      (parameters.dev_track_Eop[scifi_idx_with_offset] - min_rescales[0]) / (max_rescales[0] - min_rescales[0]);
    electron_id_features[1] =
      (parameters.dev_track_Eop3x3[scifi_idx_with_offset] - min_rescales[1]) / (max_rescales[1] - min_rescales[1]);
    electron_id_features[2] = static_cast<float>(parameters.dev_track_local_max[scifi_idx_with_offset]);
    electron_id_features[3] = (logdb - min_rescales[3]) / (max_rescales[3] - min_rescales[3]);
    electron_id_features[4] = (logdx - min_rescales[4]) / (max_rescales[4] - min_rescales[4]);
    electron_id_features[5] = (logdy - min_rescales[5]) / (max_rescales[5] - min_rescales[5]);
    electron_id_features[6] = (logdxy - min_rescales[6]) / (max_rescales[6] - min_rescales[6]);
  }
}
