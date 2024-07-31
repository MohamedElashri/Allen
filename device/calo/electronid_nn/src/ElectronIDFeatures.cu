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
#include "CaloConstants.cuh"
#include "ElectronIDFeatures.cuh"

INSTANTIATE_ALGORITHM(electronid_features::electronid_features_t)
void electronid_features::electronid_features_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_electronid_features_t>(
    arguments, Calo::Constants::n_electron_id_features * first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
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

  constexpr int input_size = Calo::Constants::n_electron_id_features;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;
    float* electron_id_features = parameters.dev_electronid_features + input_size * scifi_idx_with_offset;
    int region = parameters.dev_region[scifi_idx_with_offset];
    float region_s = Calo::Constants::region_size_0 + region * Calo::Constants::region_size_1 +
                     Calo::Constants::region_size_2 * region * region; // Get the region size from the region index:
    // 0 -> 121.2 mm
    // 1 -> 60.6 mm
    // 2 -> 40.4 mm
    float region_s2 = region_s * region_s;
    float logdb = log_feature(parameters.dev_delta_barycenter[scifi_idx_with_offset] / region_s2);
    ;
    float logdx = log_feature(parameters.dev_dispersion_x[scifi_idx_with_offset] / region_s2);
    float logdy = log_feature(parameters.dev_dispersion_y[scifi_idx_with_offset] / region_s2);
    float logdxy = log_feature(parameters.dev_dispersion_xy[scifi_idx_with_offset]);

    electron_id_features[0] = parameters.dev_track_Eop[scifi_idx_with_offset];
    electron_id_features[1] = parameters.dev_track_Eop3x3[scifi_idx_with_offset];
    electron_id_features[2] = logdb;
    electron_id_features[3] = logdx;
    electron_id_features[4] = logdy;
    electron_id_features[5] = logdxy;
    for (unsigned i = 0; i < input_size; i++) {
      electron_id_features[i] = rescale(electron_id_features[i], i, min_rescales, max_rescales);
    }
  }
}
