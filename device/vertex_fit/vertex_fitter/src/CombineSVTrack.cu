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
#include "CombineSVTrack.cuh"
#include "States.cuh"

INSTANTIATE_ALGORITHM(CombineSVTrack::combine_sv_track_t)

__global__ void create_views(CombineSVTrack::Parameters parameters)
{
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned offset = parameters.dev_combination_offsets[event_number];
  const unsigned n_sv_track_combinations = parameters.dev_combination_offsets[event_number + 1] - offset;
  const auto pv_table = parameters.dev_sv_track_pv_tables[event_number];

  for (unsigned i = threadIdx.x; i < n_sv_track_combinations; i += blockDim.x) {
    const int i_pv = pv_table.pv(i);
    new (parameters.dev_sv_track_composite_view + offset + i) Allen::Views::Physics::CompositeParticle {
      parameters.dev_sv_track_pointers[offset + i],
      parameters.dev_sv_track_fit_results_view + event_number,
      i_pv >= 0 ? parameters.dev_pvs + PV::max_number_vertices * event_number + i_pv : nullptr,
      2,
      i};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_sv_track_fit_results_view + event_number) Allen::Views::Physics::SecondaryVertices {
      parameters.dev_sv_track_fit_results, parameters.dev_combination_offsets, event_number, number_of_events};

    new (parameters.dev_sv_track_composites_view + event_number) Allen::Views::Physics::CompositeParticles {
      parameters.dev_sv_track_composite_view, parameters.dev_combination_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_composites_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_sv_track_composites_view, number_of_events};
  }
}

void CombineSVTrack::combine_sv_track_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_track_pointers_t>(arguments, first<host_number_of_combinations_t>(arguments));
  set_size<dev_sv_track_composite_view_t>(arguments, first<host_number_of_combinations_t>(arguments));
  set_size<dev_sv_track_composites_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_composites_view_t>(arguments, 1);
  set_size<dev_sv_track_pv_ip_t>(
    arguments, Associate::Consolidated::table_size(first<host_number_of_combinations_t>(arguments)));
  set_size<dev_sv_track_pv_tables_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sv_track_fit_results_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sv_track_fit_results_t>(
    arguments, 14 * sizeof(uint32_t) * first<host_number_of_combinations_t>(arguments));
}

void CombineSVTrack::combine_sv_track_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_sv_track_composite_view_t>(arguments, 0, context);
  Allen::memset_async<dev_sv_track_fit_results_t>(arguments, 0, context);
  global_function(combine_sv_track)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
  global_function(create_views)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(arguments);
}

__global__ void CombineSVTrack::combine_sv_track(CombineSVTrack::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const unsigned combination_offset = parameters.dev_combination_offsets[event_number];
  const unsigned n_combinations_evt = parameters.dev_combination_offsets[event_number + 1] - combination_offset;
  const unsigned total_number_of_combinations = parameters.dev_combination_offsets[number_of_events];
  const unsigned idx_offset = VertexFit::max_sv_track_combinations * event_number;
  const unsigned* event_sv_idx = parameters.dev_sv_idx + idx_offset;
  const unsigned* event_track_idx = parameters.dev_track_idx + idx_offset;

  // Get SVs, tracks and PVs
  const auto svs = parameters.dev_svs->container(event_number);
  const auto tracks = parameters.dev_tracks->container(event_number);
  const unsigned n_pvs_event = *(parameters.dev_npvs + event_number);
  Allen::device::span<PV::Vertex const> pvs {parameters.dev_pvs + event_number * PV::max_number_vertices, n_pvs_event};

  // SV -> PV table.
  Associate::Consolidated::Table sv_pv_ip {parameters.dev_sv_track_pv_ip, total_number_of_combinations};
  Associate::Consolidated::EventTable pv_table = sv_pv_ip.event_table(combination_offset, n_combinations_evt);
  parameters.dev_sv_track_pv_tables[event_number] = Allen::Views::Physics::PVTable {
    parameters.dev_sv_track_pv_ip, combination_offset, total_number_of_combinations, n_combinations_evt};

  parameters.dev_sv_track_fit_results_view[event_number] = Allen::Views::Physics::SecondaryVertices {
    parameters.dev_sv_track_fit_results, parameters.dev_combination_offsets, event_number, number_of_events};

  for (unsigned i_comb = threadIdx.x; i_comb < n_combinations_evt; i_comb += blockDim.x) {
    const auto sv = svs.particle(event_sv_idx[i_comb]);
    const auto track = tracks.particle(event_track_idx[i_comb]);
    const auto sv_vx = sv.vertex();
    const auto t_s = track.state();
    // Check the POCA and set a reasonable seed position for the decay vertex.
    float svt_vx_x = -999.f, svt_vx_y = -999.f, svt_vx_z = -999.f;
    Allen::Views::Physics::state_poca(sv.get_state(), t_s.operator MiniState(), svt_vx_x, svt_vx_y, svt_vx_z);
    const float svt_vx_px = sv_vx.px() + t_s.px();
    const float svt_vx_py = sv_vx.py() + t_s.py();
    const float svt_vx_pz = sv_vx.pz() + t_s.pz();

    float minip = std::numeric_limits<float>::quiet_NaN();
    int pv_idx = -1;
    for (unsigned ipv = 0; ipv < n_pvs_event; ipv++) {
      auto pv = pvs[ipv];
      const auto tmp_svip = VertexFit::ip(
        pv.position.x,
        pv.position.y,
        pv.position.z,
        svt_vx_x,
        svt_vx_y,
        svt_vx_z,
        svt_vx_px / svt_vx_pz,
        svt_vx_py / svt_vx_pz);
      if (tmp_svip < minip || pv_idx < 0) {
        minip = tmp_svip;
        pv_idx = ipv;
      }
    }
    pv_table.pv(i_comb) = pv_idx;
    parameters.dev_sv_track_pointers[combination_offset + i_comb] = {
      svs.particle_pointer(event_sv_idx[i_comb]), tracks.particle_pointer(event_track_idx[i_comb]), nullptr, nullptr};

    const unsigned nvrt = Allen::Views::Physics::SecondaryVertex::nb_elements_vrt;
    float* fbase = reinterpret_cast<float*>(parameters.dev_sv_track_fit_results.data());
    const unsigned index = combination_offset + i_comb;
    fbase[nvrt * index] = svt_vx_x;
    fbase[nvrt * index + 1] = svt_vx_y;
    fbase[nvrt * index + 2] = svt_vx_z;
    fbase[nvrt * index + 3] = svt_vx_px;
    fbase[nvrt * index + 4] = svt_vx_py;
    fbase[nvrt * index + 5] = svt_vx_pz;
  }
}
