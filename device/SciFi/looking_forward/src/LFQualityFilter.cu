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
#include "LFQualityFilter.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(lf_quality_filter::lf_quality_filter_t)

void lf_quality_filter::lf_quality_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_offsets_long_tracks_t>(
    arguments, first<host_number_of_events_t>(arguments) * LookingForward::num_atomics + 1);
  set_size<host_number_of_reconstructed_scifi_tracks_t>(arguments, 1);
  set_size<dev_scifi_tracks_t>(
    arguments,
    first<host_number_of_reconstructed_input_tracks_t>(arguments) * SciFi::Constants::max_SciFi_tracks_per_UT_track);
  set_size<dev_scifi_lf_y_parametrization_length_filter_t>(
    arguments,
    2 * first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_maximum_number_of_candidates_per_ut_track);
  set_size<dev_scifi_lf_parametrization_consolidate_t>(
    arguments,
    7 * first<host_number_of_reconstructed_input_tracks_t>(arguments) *
      SciFi::Constants::max_SciFi_tracks_per_UT_track);
  set_size<dev_lf_quality_of_tracks_t>(
    arguments,
    m_maximum_number_of_candidates_per_ut_track * first<host_number_of_reconstructed_input_tracks_t>(arguments));
}

namespace geom {
  __constant__ extern float dev_average_dxdy[LookingForward::number_of_uv_layers];
} // namespace geom

void lf_quality_filter::lf_quality_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_offsets_long_tracks_t>(arguments, 0, context);

  global_function(lf_quality_filter)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    forward_ghost_killer.getDevicePointer(),
    forward_ghost_killer_no_ut.getDevicePointer(),
    m_maximum_number_of_candidates_per_ut_track,
    m_max_diff_ty_window,
    m_factor_9_hits,
    m_factor_10_hits,
    m_factor_11_hits,
    m_factor_12_hits,
    m_max_final_quality,
    m_ghost_killer_threshold);

  if (m_verbosity >= logger::debug) {
    print<dev_offsets_long_tracks_t>(arguments);
  }

  PrefixSum::prefix_sum<dev_offsets_long_tracks_t, host_number_of_reconstructed_scifi_tracks_t>(
    *this, arguments, context);
}

namespace {

  __device__ inline MiniState get_scifi_state(float x0, float tx, float curvature, float d_ratio, float y0, float ty)
  {
    const auto dz = SciFi::Constants::ZEndT - LookingForward::z_mid_t;
    return MiniState {x0 + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz),
                      y0 + ty * SciFi::Constants::ZEndT,
                      SciFi::Constants::ZEndT,
                      tx + 2.f * dz * curvature + 3.f * dz * dz * curvature * d_ratio,
                      ty};
  }

} // namespace

template<bool with_ut, typename T>
__device__ void quality_filter(
  lf_quality_filter::Parameters parameters,
  const T* tracks,
  const LFQualityNN::DeviceType* dev_forward_ghost_killer,
  const unsigned maximum_number_of_candidates_per_ut_track,
  const float max_diff_ty_window,
  const float factor_9_hits,
  const float factor_10_hits,
  const float factor_11_hits,
  const float factor_12_hits,
  const float max_final_quality,
  const float ghost_killer_threshold)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto input_tracks_view = tracks->container(event_number);

  const int event_number_of_tracks = input_tracks_view.size();
  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  // SciFi hits
  const unsigned total_number_of_hits = parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_zones];

  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};
  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_hits};

  const auto number_of_tracks = parameters.dev_scifi_lf_length_filtered_atomics[event_number];
  const auto event_offset = scifi_hit_count.event_offset();

  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index = event_tracks_offset * maximum_number_of_candidates_per_ut_track + i;
    const SciFi::TrackHits& track = parameters.dev_scifi_lf_length_filtered_tracks[scifi_track_index];
    const auto& input_state = parameters.dev_input_states[event_tracks_offset + track.input_track_index];

    bool hit_in_T1_UV = false;
    bool hit_in_T2_UV = false;
    bool hit_in_T3_UV = false;
    unsigned number_of_uv_hits = 0;
    for (unsigned j = 3; j < track.hitsNum; ++j) {
      const auto hit_index = event_offset + track.hits[j];
      const auto layer_number = scifi_hits.planeCode(hit_index) / 2;

      const bool current_hit_in_T1_UV = (layer_number == 1) || (layer_number == 2);
      const bool current_hit_in_T2_UV = (layer_number == 5) || (layer_number == 6);
      const bool current_hit_in_T3_UV = (layer_number == 9) || (layer_number == 10);

      hit_in_T1_UV |= current_hit_in_T1_UV;
      hit_in_T2_UV |= current_hit_in_T2_UV;
      hit_in_T3_UV |= current_hit_in_T3_UV;
      number_of_uv_hits += current_hit_in_T1_UV + current_hit_in_T2_UV + current_hit_in_T3_UV;
    }

    // Load parametrization
    const auto a1 = parameters.dev_scifi_lf_parametrization_length_filter[scifi_track_index];
    const auto b1 = parameters.dev_scifi_lf_parametrization_length_filter
                      [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto c1 = parameters.dev_scifi_lf_parametrization_length_filter
                      [2 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
    const auto d_ratio = parameters.dev_scifi_lf_parametrization_length_filter
                           [3 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];

    // Do Y line fit
    const auto y_lms_fit = LookingForward::least_mean_square_y_fit(
      track, number_of_uv_hits, scifi_hits, a1, b1, c1, d_ratio, event_offset, geom::dev_average_dxdy);

    // Save Y line fit
    parameters.dev_scifi_lf_y_parametrization_length_filter[scifi_track_index] = std::get<1>(y_lms_fit);
    parameters.dev_scifi_lf_y_parametrization_length_filter
      [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index] = std::get<2>(y_lms_fit);

    const float y_fit_contribution = std::get<0>(y_lms_fit) / LookingForward::range_y_fit_end;

    const auto in_ty_window = fabsf(std::get<2>(y_lms_fit) - input_state.ty()) < max_diff_ty_window;
    const bool acceptable = hit_in_T1_UV && hit_in_T2_UV && hit_in_T3_UV &&
                            (track.hitsNum >= LookingForward::min_hits_or_ty_window || in_ty_window);

    // Combined value
    const auto combined_value = track.quality / (track.hitsNum - 3);

    float updated_track_quality = acceptable ? combined_value + y_fit_contribution : 10000.f;

    // Apply multipliers to quality of tracks depending on number of hits
    if (track.hitsNum == 9) {
      updated_track_quality *= factor_9_hits;
    }
    else if (track.hitsNum == 10) {
      updated_track_quality *= factor_10_hits;
    }
    else if (track.hitsNum == 11) {
      updated_track_quality *= factor_11_hits;
    }
    else if (track.hitsNum == 12) {
      updated_track_quality *= factor_12_hits;
    }

    parameters.dev_scifi_quality_of_tracks[scifi_track_index] = updated_track_quality;

    // // This code is to keep all the tracks
    // const auto insert_index = atomicAdd(parameters.dev_offsets_long_tracks + event_number, 1);
    // parameters.dev_scifi_tracks[ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track +
    // insert_index] = track;
  }

  // Due to parameters.dev_scifi_quality_of_tracks RAW dependency
  __syncthreads();

  for (int i = threadIdx.x; i < event_number_of_tracks; i += blockDim.x) {
    float best_quality = max_final_quality;
    int best_track_index = -1;
    assert(number_of_tracks < INT_MAX); // assertion to make sure best_track_index is in range
    for (unsigned j = 0; j < number_of_tracks; j++) {
      const auto index = event_tracks_offset * maximum_number_of_candidates_per_ut_track + j;
      const auto track_quality = parameters.dev_scifi_quality_of_tracks[index];
      const SciFi::TrackHits& track = parameters.dev_scifi_lf_length_filtered_tracks[index];

      if (track.input_track_index == i && track_quality < best_quality) {
        best_quality = track_quality;
        best_track_index = j;
      }
    }

    if (best_track_index != -1) {

      const auto scifi_track_index = event_tracks_offset * maximum_number_of_candidates_per_ut_track + best_track_index;
      const auto& track = parameters.dev_scifi_lf_length_filtered_tracks[scifi_track_index];
      // Save track parameters to last container as well
      const auto a1 = parameters.dev_scifi_lf_parametrization_length_filter[scifi_track_index];
      const auto b1 = parameters.dev_scifi_lf_parametrization_length_filter
                        [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = parameters.dev_scifi_lf_parametrization_length_filter
                        [2 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto d_ratio =
        parameters.dev_scifi_lf_parametrization_length_filter
          [3 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto y_b = parameters.dev_scifi_lf_y_parametrization_length_filter[scifi_track_index];
      const auto y_m = parameters.dev_scifi_lf_y_parametrization_length_filter
                         [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];

      const auto scifi_state = get_scifi_state(c1, b1, a1, d_ratio, y_b, y_m);

      const auto velo_state = parameters.dev_input_states[event_tracks_offset + track.input_track_index];

      // Prepare inputs for ghost killer
      constexpr float zMatchY = 10000.f;
      constexpr float zMatchX = 5000.f;
      const auto scifi_x0 = scifi_state.x() - scifi_state.tx() * scifi_state.z();
      const auto velo_x0 = velo_state.x() - velo_state.tx() * velo_state.z();
      const auto scifi_y0 = scifi_state.y() - scifi_state.ty() * scifi_state.z();
      const auto velo_y0 = velo_state.y() - velo_state.ty() * velo_state.z();
      const auto zMagnet = (velo_x0 - scifi_x0) / (scifi_state.tx() - velo_state.tx());
      const auto distX = (velo_x0 + velo_state.tx() * zMatchX) - (scifi_x0 + scifi_state.tx() * zMatchX);
      const auto distY = (velo_y0 + velo_state.ty() * zMatchY) - (scifi_y0 + scifi_state.ty() * zMatchY);
      const auto dSlopeX = scifi_state.tx() - velo_state.tx();
      const auto dSlopeY = scifi_state.ty() - velo_state.ty();
      const auto velo_rho = hypotf(velo_state.tx(), velo_state.ty());
      const auto velo_eta = asinhf(1.f / velo_rho);

      float ghost_killer_inputs[LFQualityNN::DeviceType::nInput] = {
        zMagnet, -fabsf(distX), distY, -fabsf(dSlopeX), dSlopeY, velo_eta, logf(best_quality)};

      const auto ghost_killer_score = dev_forward_ghost_killer->evaluate(ghost_killer_inputs);

      if (ghost_killer_score < ghost_killer_threshold) {
        const int insert_index = atomicAdd(parameters.dev_offsets_long_tracks + event_number, 1);
        assert(insert_index < event_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track);

        const auto new_scifi_track_index =
          event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + insert_index;
        // track.ghost_probability = ghost_killer_score;
        parameters.dev_scifi_tracks[new_scifi_track_index] = track;

        // Save track parameters to last container as well
        parameters.dev_scifi_lf_parametrization_consolidate[new_scifi_track_index] = a1;
        parameters.dev_scifi_lf_parametrization_consolidate
          [total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = b1;
        parameters.dev_scifi_lf_parametrization_consolidate
          [2 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = c1;
        parameters.dev_scifi_lf_parametrization_consolidate
          [3 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] =
          d_ratio;
        parameters.dev_scifi_lf_parametrization_consolidate
          [4 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = y_b;
        parameters.dev_scifi_lf_parametrization_consolidate
          [5 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] = y_m;
        parameters.dev_scifi_lf_parametrization_consolidate
          [6 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + new_scifi_track_index] =
          ghost_killer_score;
      }
    }
  }
}

__global__ void lf_quality_filter::lf_quality_filter(
  lf_quality_filter::Parameters parameters,
  const LFQualityNN::DeviceType* dev_forward_ghost_killer,
  const LFQualityNN::DeviceType* dev_forward_no_ut_ghost_killer,
  const unsigned maximum_number_of_candidates_per_ut_track,
  const float max_diff_ty_window,
  const float factor_9_hits,
  const float factor_10_hits,
  const float factor_11_hits,
  const float factor_12_hits,
  const float max_final_quality,
  const float ghost_killer_threshold)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventVeloUTTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    quality_filter<true>(
      parameters,
      ut_tracks,
      dev_forward_ghost_killer,
      maximum_number_of_candidates_per_ut_track,
      max_diff_ty_window,
      factor_9_hits,
      factor_10_hits,
      factor_11_hits,
      factor_12_hits,
      max_final_quality,
      ghost_killer_threshold);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    quality_filter<false>(
      parameters,
      velo_tracks,
      dev_forward_no_ut_ghost_killer,
      maximum_number_of_candidates_per_ut_track,
      max_diff_ty_window,
      factor_9_hits,
      factor_10_hits,
      factor_11_hits,
      factor_12_hits,
      max_final_quality,
      ghost_killer_threshold);
  }
}
