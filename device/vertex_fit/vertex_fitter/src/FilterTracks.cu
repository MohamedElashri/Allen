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
#include "FilterTracks.cuh"
#include "VertexFitDeviceFunctions.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"
#include "States.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(FilterTracks::filter_tracks_t)

void FilterTracks::filter_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_svs_t>(arguments, 1);
  set_size<dev_svs_trk1_idx_t>(arguments, VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_svs_trk2_idx_t>(arguments, VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_sv_poca_t>(arguments, 3 * VertexFit::max_svs * first<host_number_of_events_t>(arguments));
  set_size<dev_track_prefilter_result_t>(arguments, first<host_number_of_tracks_t>(arguments));
}

void FilterTracks::filter_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_sv_offsets_t>(arguments, 0, context);

  global_function(prefilter_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_prefilter, context)(
    arguments,
    m_minpt_both,
    m_minipchi2_both,
    m_maxchi2ndof,
    m_minip_both,
    m_require_muon.value(),
    m_require_electron.value(),
    m_require_lepton.value());

  global_function(filter_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim_filter, context)(
    arguments,
    m_require_os_pair.value(),
    m_require_same_pv.value(),
    m_maxassocipchi2,
    m_minpt_either,
    m_minip_either,
    m_minipchi2_either,
    m_minsumpt,
    m_maxdoca);

  PrefixSum::prefix_sum<dev_sv_offsets_t, host_number_of_svs_t>(*this, arguments, context);
}

__global__ void FilterTracks::prefilter_tracks(
  FilterTracks::Parameters parameters,
  const float track_min_pt_both,
  const float track_min_ipchi2_both,
  const float track_max_chi2ndof,
  const float track_min_ip_both,
  const bool require_muon,
  const bool require_electron,
  const bool require_lepton)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  const unsigned n_tracks = long_track_particles.size();
  bool* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();

  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    const auto track = long_track_particles.particle(i_track);
    const auto state = track.state();
    const float pt = state.pt();
    const float ipchi2 = track.ip_chi2();
    const float ip = track.ip();
    const float chi2ndof = track.chi2() / track.ndof();
    bool dec = pt > track_min_pt_both && ipchi2 > track_min_ipchi2_both && chi2ndof < track_max_chi2ndof &&
               ip > track_min_ip_both;
    if (require_muon) dec &= track.is_muon();
    if (require_electron) dec &= track.is_electron();
    if (require_lepton) dec &= track.is_lepton();
    event_prefilter_result[i_track] = dec;
  }
}

__global__ void FilterTracks::filter_tracks(
  FilterTracks::Parameters parameters,
  const bool require_os_pair,
  const bool require_same_pv,
  const float max_assoc_ipchi2,
  const float track_min_pt_either,
  const float track_min_ip_either,
  const float track_min_ipchi2_either,
  const float sum_pt_min,
  const float doca_max)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned idx_offset = event_number * VertexFit::max_svs;
  unsigned* event_sv_number = parameters.dev_sv_offsets + event_number;
  unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);
  bool* event_prefilter_result = parameters.dev_track_prefilter_result + long_track_particles.offset();
  const unsigned n_scifi_tracks = long_track_particles.size();

  // Loop over tracks.
  for (unsigned i_track = threadIdx.x; i_track < n_scifi_tracks; i_track += blockDim.x) {
    // Filter first track.
    if (!event_prefilter_result[i_track]) continue;
    const auto trackA = long_track_particles.particle(i_track);
    const float ipchi2A = trackA.ip_chi2();
    const float ipA = trackA.ip();
    const float ptA = trackA.state().pt();

    for (unsigned j_track = threadIdx.y + i_track + 1; j_track < n_scifi_tracks; j_track += blockDim.y) {
      // Filter second track.
      if (!event_prefilter_result[j_track]) continue;
      const auto trackB = long_track_particles.particle(j_track);
      const float ipchi2B = trackB.ip_chi2();
      const float ipB = trackB.ip();
      const float ptB = trackB.state().pt();

      // OS pair cut. Tracks must have opposite-sign charge.
      if (require_os_pair) {
        if (trackA.state().charge() * trackB.state().charge() > 0.f) continue;
      }

      // Same PV cut. If tracks are "prompt", they must be associated to the same PV.
      if (require_same_pv) {
        if (&(trackA.pv()) != &(trackB.pv()) && ipchi2A < max_assoc_ipchi2 && ipchi2B < max_assoc_ipchi2) {
          continue;
        }
      }

      // Check cuts on at least one track
      if (ptA < track_min_pt_either && ptB < track_min_pt_either) continue;
      if (ipA < track_min_ip_either && ipB < track_min_ip_either) continue;
      if (ipchi2A < track_min_ipchi2_either && ipchi2B < track_min_ipchi2_either) continue;

      // Check the sum of pt.
      if (ptA + ptB < sum_pt_min) continue;

      const auto trackA_ministate = trackA.state().operator MiniState(),
                 trackB_ministate = trackB.state().operator MiniState();

      // Check the DOCA.
      const float doca = Allen::Views::Physics::state_doca(trackA_ministate, trackB_ministate);
      if (doca > doca_max) continue;

      // Check the POCA.
      float x;
      float y;
      float z;
      if (!Allen::Views::Physics::state_poca(trackA_ministate, trackB_ministate, x, y, z)) {
        continue;
      }

      unsigned vertex_idx = atomicAdd(event_sv_number, 1);

      // Leave the loop if the maximum number of SVs is exceeded.
      if (vertex_idx >= VertexFit::max_svs) break;

      event_poca[3 * vertex_idx] = x;
      event_poca[3 * vertex_idx + 1] = y;
      event_poca[3 * vertex_idx + 2] = z;
      event_svs_trk1_idx[vertex_idx] = i_track;
      event_svs_trk2_idx[vertex_idx] = j_track;
    }
  }

  __syncthreads();

  // If there were too many SVs in the event, set the number of SVs to zero.
  if (event_sv_number[0] > VertexFit::max_svs) {

    // We could also set the event_poca and event_svs_trk{1,2}_idx arrays to 0,
    // but these are never initialized in the first place, and 0 is a meaningful
    // value all of these arrays.
    if (threadIdx.x == 0) {
      event_sv_number[0] = 0;
    }
  }
}
