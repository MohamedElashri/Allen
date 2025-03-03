/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// This
#include "DownstreamV2FinalFit.cuh"

// UT
#include "UTEventModel.cuh"

// Helpers
#include "LinearAlgebra.cuh"

// Downstream
#include "DownstreamV2Extrapolation.cuh"
#include "DownstreamV2Constants.cuh"

// Primitives
#include "PrefixSum.cuh"

#include "SciFiEventModel.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_final_fits::downstream_v2_final_fits_t);

void downstream_v2_final_fits::downstream_v2_final_fits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_tracks = first<host_number_of_selected_downstream_compact_tracks_t>(arguments);
  const auto number_of_events = first<host_number_of_events_t>(arguments);

  // Set sizes
  set_size<host_number_of_final_downstream_compact_tracks_t>(arguments, 1);
  set_size<dev_final_downstream_compact_track_offsets_t>(arguments, number_of_events + 1);
  set_size<dev_final_downstream_compact_tracks_t>(arguments, number_of_tracks);
  set_size<dev_final_downstream_compact_track_ghost_probs_t>(arguments, number_of_tracks);
  set_size<dev_final_downstream_compact_track_states_t>(arguments, number_of_tracks);
  set_size<dev_final_downstream_compact_track_qops_t>(arguments, number_of_tracks);
}

void downstream_v2_final_fits::downstream_v2_final_fits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{

  Allen::memset_async<dev_final_downstream_compact_track_offsets_t>(arguments, 0, context);

  global_function(downstream_v2_final_fits)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    constants.host_magnet_polarity[0],
    m_downstream_ghost_killer.getDevicePointer(),
    m_ghost_killing_threshold);

  if (m_verbosity >= logger::debug) {
    print<dev_final_downstream_compact_track_offsets_t>(arguments);
  }

  PrefixSum::prefix_sum<dev_final_downstream_compact_track_offsets_t, host_number_of_final_downstream_compact_tracks_t>(
    *this, arguments, context);
}

__global__ void downstream_v2_final_fits::downstream_v2_final_fits(
  Parameters parameters,
  float magnet_polarity,
  const GhostKiller::DeviceType* ghost_killer,
  float ghost_killing_threshold)
{
  // Basics
  const auto number_of_events = parameters.dev_number_of_events[0];
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // UT hits
  const auto total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_hit_offsets.event_offset()};

  // Downstream Input
  const auto input_offset = parameters.dev_fitted_downstream_compact_track_offsets[event_number];
  const auto output_offset = parameters.dev_selected_downstream_compact_track_offsets[event_number];
  const auto input_size = parameters.dev_selected_downstream_compact_track_offsets[event_number + 1] - output_offset;
  const auto input_tracks = parameters.dev_selected_downstream_compact_tracks + input_offset;

  // Output
  auto output_counter = parameters.dev_final_downstream_compact_track_offsets + event_number;
  auto output_tracks = parameters.dev_final_downstream_compact_tracks + output_offset;
  auto output_ghost_probs = parameters.dev_final_downstream_compact_track_ghost_probs + output_offset;
  auto output_states = parameters.dev_final_downstream_compact_track_states + output_offset;
  auto output_qops = parameters.dev_final_downstream_compact_track_qops + output_offset;

  // Loop over all tracks
  for (unsigned track_idx = threadIdx.x; track_idx < input_size; track_idx += blockDim.x) {
    const auto track = input_tracks[track_idx];
    const auto scifi_state = parameters.dev_seeding_states[track.scifi_idx];

    // Compute zMagnet
    const auto zMagnet = Downstream::Extrapolation::get_zMagnet(scifi_state);
    const auto xMagnet = scifi_state.xAt(zMagnet);

    // Fit UT state
    bool is_fit_success;
    Downstream::Structs::CompactState ut_state;
    {
      float ATA[6] = {0, 0, 0, 0, 0, 0};
      float ATY[3] = {0, 0, 0};
      for (unsigned hit = 0; hit < 4; hit++) {
        const auto w = ut_hits.weight(track.ut_hits[hit]);
        const auto z0 = ut_hits.zAtYEq0(track.ut_hits[hit]);
        const auto z = z0 - UT::Constants::zMidUT;
        const auto x = ut_hits.xAtYEq0(track.ut_hits[hit]);
        const auto dxdy = ut_hits.dxDy(track.ut_hits[hit]);
        const auto t = -dxdy;
        const auto yy = scifi_state.yAt(z0);
        const auto u = x + dxdy * yy;
        ATA[0] += w;
        ATA[1] += w * z;
        ATA[2] += w * z * z;
        ATA[3] += w * t;
        ATA[4] += w * t * z;
        ATA[5] += w * t * t;
        ATY[0] += w * u;
        ATY[1] += w * u * z;
        ATY[2] += w * u * t;
      }
      float fr[3];
      is_fit_success = LinAlg::SolveCholesky<3>(ATA, ATY, fr);

      ut_state.x() = fr[0];
      ut_state.tx() = fr[1];
      ut_state.y() = fr[2] + scifi_state.yAt(UT::Constants::zMidUT);
      ut_state.ty() = (scifi_state.y() - ut_state.y()) / (scifi_state.z() - ut_state.z());
    }
    if (!is_fit_success) continue;

    // Compute the tracking bias
    float bias0, bias12;
    {
      const auto l3_x = ut_hits.xAtYEq0(track.ut_hits[3]);
      const auto l3_z = ut_hits.zAtYEq0(track.ut_hits[3]);
      float tx = (xMagnet - l3_x) / (zMagnet - l3_z);
      float x0 = l3_x - l3_z * tx;

      float dist[3];
      for (unsigned i = 0; i < 3; i++) {
        const auto hit_z = ut_hits.zAtYEq0(track.ut_hits[i]);
        const auto yAtHitZ = scifi_state.yAt(hit_z);
        const auto hit_x = ut_hits.xAt(track.ut_hits[i], yAtHitZ);
        dist[i] = hit_x - (x0 + tx * hit_z);
        if (i == 0) {
          tx = (hit_x - l3_x) / (hit_z - l3_z);
          x0 = hit_x - tx * hit_z;
        }
      }
      bias0 = fabsf(dist[0]);
      bias12 = fabsf(dist[1] + dist[2]);
    }

    // Ghost probability
    float score;
    {
      const auto distX = fabsf(scifi_state.xAt(zMagnet) - ut_state.xAt(zMagnet));
      const auto distY = fabsf(scifi_state.yAt(UT::Constants::zMidUT) - ut_state.y());
      const auto dSlopeX = fabsf(scifi_state.tx() - ut_state.tx());
      const auto dSlopeY = fabsf(scifi_state.ty() - ut_state.ty());
      const auto eta = asinhf(1.f / hypotf(ut_state.tx(), ut_state.ty()));
      const auto phi = fabsf(fabsf(atan2f(ut_state.tx(), ut_state.ty())) - 3.14f / 2.f);
      const auto ft_eta = asinhf(1.f / hypotf(scifi_state.tx(), scifi_state.ty()));

      float inputs[13] = {distX,
                          distY,
                          dSlopeX,
                          dSlopeY,
                          fabsf(ut_state.x()),
                          fabsf(ut_state.y()),
                          fabsf(ut_state.xAt(0)),
                          fabsf(ut_state.yAt(0)),
                          bias0,
                          bias12,
                          phi,
                          eta,
                          ft_eta};
      score = ghost_killer->evaluate(inputs);
    }

    if (!std::isfinite(score) || score > ghost_killing_threshold) continue;

    const auto idx = atomicAdd(output_counter, 1u);
    output_tracks[idx] = track;
    output_ghost_probs[idx] = score;
    output_states[idx] = ut_state;
    output_qops[idx] =
      Downstream::Extrapolation::get_qop(ut_state.tx(), ut_state.ty(), scifi_state.tx(), magnet_polarity);
  }
}