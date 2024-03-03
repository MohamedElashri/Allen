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

INSTANTIATE_ALGORITHM(FilterSVTrack::filter_sv_track_t)

void FilterSVTrack::filter_sv_track_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_combination_number_t>(arguments, first<host_number_of_events_t>(arguments));
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
  Allen::memset_async<dev_combination_number_t>(arguments, 0, context);

  global_function(filter_sv_track)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);
}

__global__ void FilterSVTrack::filter_sv_track(FilterSVTrack::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned sv_idx_offset = event_number * VertexFit::max_sv_track_combinations;
  unsigned* event_sv_idx = parameters.dev_sv_idx + sv_idx_offset;
  unsigned* event_track_idx = parameters.dev_track_idx + sv_idx_offset;
  unsigned* event_combination_number = parameters.dev_combination_number + event_number;

  const auto svs = parameters.dev_svs->container(event_number);
  const auto tracks = parameters.dev_tracks->container(event_number);
  for (unsigned i_sv = threadIdx.x; i_sv < svs.size(); i_sv += blockDim.x) {
    const auto sv = svs.particle(i_sv);
    const auto sv_vx = sv.vertex();
    const auto sv_vxz = sv_vx.z();
    const bool sv_decision = sv_vx.chi2() < parameters.SV_VCHI2_max && parameters.SV_VZ_min < sv_vxz &&
                             sv_vxz < parameters.SV_VZ_max && sv.fdchi2() > parameters.SV_BPVVDCHI2_min &&
                             sv.dz() > parameters.SV_BPVVDZ_min && sv.drho() > parameters.SV_BPVVDRHO_min &&
                             sv.dira() > parameters.SV_BPVDIRA_min;
    if (!sv_decision) continue;
    for (unsigned i_track = threadIdx.y; i_track < tracks.size(); i_track += blockDim.y) {
      const auto track = tracks.particle(i_track);
      const auto t_s = track.state();
      const bool track_decision = t_s.pt() > parameters.T_PT_min && track.ip_chi2() > parameters.T_MIPCHI2_min &&
                                  track.chi2() / track.ndof() < parameters.T_CHI2NDF_max;
      if (!track_decision) continue;
      const auto sv_ministate = sv.get_state(), t_ministate = track.state().operator MiniState();
      if (Allen::Views::Physics::state_doca(sv_ministate, t_ministate) > parameters.SV_T_DOCA_max) continue;
      const auto c0_state = static_cast<const Allen::Views::Physics::BasicParticle*>(sv.child(0))->state(),
                 c1_state = static_cast<const Allen::Views::Physics::BasicParticle*>(sv.child(1))->state();
      const auto t_tx = t_ministate.tx(), t_ty = t_ministate.ty(), c0_tx = c0_state.tx(), c1_tx = c1_state.tx(),
                 c0_ty = c0_state.ty(), c1_ty = c1_state.ty();
      const auto c0t_norm = sqrtf((t_tx * t_tx + t_ty * t_ty + 1.f) * (c0_tx * c0_tx + c0_ty * c0_ty + 1.f));
      const auto c0t_arg = (t_tx * c0_tx + t_ty * c0_ty + 1.f) / c0t_norm;
      const auto c0t_opening_angle = c0t_arg > 1.f ? 0.f : acosf(c0t_arg);
      const auto c1t_norm = sqrtf((t_tx * t_tx + t_ty * t_ty + 1.f) * (c1_tx * c1_tx + c1_ty * c1_ty + 1.f));
      const auto c1t_arg = (t_tx * c1_tx + t_ty * c1_ty + 1.f) / c1t_norm;
      const auto c1t_opening_angle = c1t_arg > 1.f ? 0.f : acosf(c1t_arg);
      if (c0t_opening_angle > parameters.opening_angle_min && c1t_opening_angle > parameters.opening_angle_min) {
        unsigned cmb_idx = atomicAdd(event_combination_number, 1);

        // Leave the loop if the maximum number of combinations is exceeded.
        if (cmb_idx >= VertexFit::max_sv_track_combinations) break;

        event_sv_idx[cmb_idx] = i_sv;
        event_track_idx[cmb_idx] = i_track;
      }
    }
  }

  __syncthreads();

  // If there are too many combinations in an event, set the number of combinations to 0.
  if (event_combination_number[0] > VertexFit::max_sv_track_combinations) {
    if (threadIdx.x == 0) {
      event_combination_number[0] = 0;
    }
  }
}
