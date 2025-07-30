/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "FilterSVTrack.cuh"
#include "States.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(FilterSVTrack::filter_sv_track_t)

void FilterSVTrack::filter_sv_track_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_combination_offsets_t>(arguments, first<host_number_of_events_t>(arguments) + 1);
  set_size<host_number_of_combinations_t>(arguments, 1);
  set_size<dev_sv_idx_t>(arguments, VertexFit::max_sv_track_combinations * first<host_number_of_events_t>(arguments));
  set_size<dev_track_idx_t>(
    arguments, VertexFit::max_sv_track_combinations * first<host_number_of_events_t>(arguments));
}

void FilterSVTrack::filter_sv_track_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_combination_offsets_t>(arguments, 0, context);

  global_function(filter_sv_track)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    m_SV_VZ_min,
    m_SV_VZ_max,
    m_SV_BPVIP_min,
    m_SV_BPVVDZ_min,
    m_SV_BPVVDRHO_min,
    m_SV_BPVDIRA_min,
    m_T_CHI2NDF_max,
    m_T_PT_min,
    m_T_MIPCHI2_min,
    m_T_MIPCHI2_max,
    m_T_MIP_min,
    m_T_MIP_max,
    m_SV_T_DOCA_max,
    m_opening_angle_min,
    m_require_same_pv.value(),
    m_require_os_pair.value());

  PrefixSum::prefix_sum<dev_combination_offsets_t, host_number_of_combinations_t>(*this, arguments, context);
}

__global__ void FilterSVTrack::filter_sv_track(
  FilterSVTrack::Parameters parameters,
  const float SV_VZ_min,
  const float SV_VZ_max,
  const float SV_BPVIP_min,
  const float SV_BPVVDZ_min,
  const float SV_BPVVDRHO_min,
  const float SV_BPVDIRA_min,
  const float T_CHI2NDF_max,
  const float T_PT_min,
  const float T_MIPCHI2_min,
  const float T_MIPCHI2_max,
  const float T_MIP_min,
  const float T_MIP_max,
  const float SV_T_DOCA_max,
  const float opening_angle_min,
  const bool require_same_pv,
  const bool require_os_pair)
{
  /*
  / For each event, check all the combinations of SVs and tracks to match the given citeria.
  / The blockDim is [128, 4, 1].
  / Tracks align with the x-axis, SVs with the y-axis.
  / Ideally we should not exceed 128 long tracks per event, so the first loop should hardly ever be executed more than
  / once.
  */
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned sv_idx_offset = event_number * VertexFit::max_sv_track_combinations;
  unsigned* event_sv_idx = parameters.dev_sv_idx + sv_idx_offset;
  unsigned* event_track_idx = parameters.dev_track_idx + sv_idx_offset;
  unsigned* event_combination_number = parameters.dev_combination_offsets + event_number;

  const auto svs = parameters.dev_svs->container(event_number);
  const auto tracks = parameters.dev_tracks->container(event_number);

  for (unsigned i_track = threadIdx.x; i_track < tracks.size(); i_track += blockDim.x) { // loop over all tracks
    if (svs.size() < threadIdx.y + 1) {
      break;
    } // break loop for threads that don't have any SVs to check
    const auto track = tracks.particle(i_track);
    const auto t_s = track.state();
    const bool track_decision = t_s.pt() > T_PT_min && track.ip_chi2() > T_MIPCHI2_min &&
                                track.ip_chi2() < T_MIPCHI2_max && track.ip() > T_MIP_min && track.ip() < T_MIP_max &&
                                track.chi2() / track.ndof() < T_CHI2NDF_max;
    if (!track_decision) continue;
    auto next_sv = svs.particle(threadIdx.y);
    const auto t_ministate = track.state().operator MiniState();
    for (unsigned i_sv = threadIdx.y; i_sv < svs.size(); i_sv += blockDim.y) {
      auto sv = next_sv;
      next_sv = (i_sv + blockDim.y < svs.size()) ? svs.particle(i_sv + blockDim.y) : sv; // Preload the next vertex
      // first make checks that would reject the SV for every track
      if (require_os_pair && sv.charge() != 0) {
        continue;
      }
      const auto sv_vxz = sv.vertex().z();
      const bool sv_decision = SV_VZ_min < sv_vxz && sv_vxz < SV_VZ_max && sv.dz() > SV_BPVVDZ_min &&
                               sv.drho() > SV_BPVVDRHO_min && sv.ip() > SV_BPVIP_min && sv.dira() > SV_BPVDIRA_min;
      if (!sv_decision) continue;
      // load the Mini State
      const auto sv_ministate = sv.get_state();
      // Check is the specific SV was created using this track
      if (sv.child_in_tree(tracks.particle_pointer(i_track))) continue;
      // Check that, if required, the track and SV come from the same PV
      if (require_same_pv && &(track.pv()) != &(sv.pv())) continue;
      // check DOCA within limit
      if (Allen::Views::Physics::state_doca(sv_ministate, t_ministate) > SV_T_DOCA_max) continue;
      // check opening angle within limit
      if (sv.min_opening_angle_in_tree(t_ministate) < opening_angle_min) continue;
      // set results counters
      unsigned cmb_idx = atomicAdd(event_combination_number, 1);
      // Leave the loop if the maximum number of combinations is exceeded.
      if (cmb_idx >= VertexFit::max_sv_track_combinations) {
        break;
      }
      event_sv_idx[cmb_idx] = i_sv;
      event_track_idx[cmb_idx] = i_track;

    } // loop over svs
  }   // loop over tracks

  __syncthreads();

  // If there are too many combinations in an event, set the number of combinations to 0.
  if (event_combination_number[0] > VertexFit::max_sv_track_combinations) {
    if (threadIdx.x == 0 && threadIdx.y == 0) {
      event_combination_number[0] = 0;
    }
  }
}
