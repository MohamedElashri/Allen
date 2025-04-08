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

#include "DownstreamMakeSecondaryVertices.cuh"
#include "DownstreamExtrapolation.cuh"

INSTANTIATE_ALGORITHM(downstream_make_secondary_vertices::downstream_make_secondary_vertices_t)

void downstream_make_secondary_vertices::downstream_make_secondary_vertices_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_sv_fit_results_t>(
    arguments, 14 * sizeof(uint32_t) * first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_sv_fit_results_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_downstream_secondary_vertices_ip_t>(
    arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_downstream_secondary_vertices_pv_t>(
    arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_two_track_sv_track_pointers_t>(
    arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_two_track_composite_view_t>(arguments, first<host_number_of_downstream_secondary_vertices_t>(arguments));
  set_size<dev_two_track_composites_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_composites_view_t>(arguments, 1);
  set_size<dev_multi_event_composites_ptr_t>(arguments, 1);
}

void downstream_make_secondary_vertices::downstream_make_secondary_vertices_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_sv_fit_results_t>(arguments, 0, context);
  Allen::memset_async<dev_two_track_composite_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_secondary_vertices_ip_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_secondary_vertices_pv_t>(arguments, 0, context);

  global_function(downstream_make_secondary_vertices)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);

  global_function(downstream_make_secondary_vertices_views)(
    dim3(first<host_number_of_events_t>(arguments)), 128, context)(arguments, m_histogram_nsvs.data(context));
}

namespace {
  __host__ __device__ void
  fill_sv(char* base_pointer, const unsigned index, const unsigned n_svs_total, const VertexFit::MiniVertex& sv)
  {
    float* fbase = reinterpret_cast<float*>(base_pointer);
    const unsigned nvrt = Allen::Views::Physics::SecondaryVertex::nb_elements_vrt;
    const unsigned ncov = Allen::Views::Physics::SecondaryVertex::nb_elements_cov;
    fbase[nvrt * index] = sv.x;
    fbase[nvrt * index + 1] = sv.y;
    fbase[nvrt * index + 2] = sv.z;
    fbase[nvrt * index + 3] = sv.px;
    fbase[nvrt * index + 4] = sv.py;
    fbase[nvrt * index + 5] = sv.pz;

    // The downstream composite model does not account for errors.
    // Therefore, we repurpose some of the memory originally allocated for error storage to hold other information
    fbase[nvrt * n_svs_total + ncov * index + 0] = sv.doca;
    fbase[nvrt * n_svs_total + ncov * index + 1] = sv.quality;
    fbase[nvrt * n_svs_total + ncov * index + 2] = sv.Armenteros_x;
    fbase[nvrt * n_svs_total + ncov * index + 3] = sv.Armenteros_y;
    fbase[nvrt * n_svs_total + ncov * index + 4] = sv.helicity;
  }
} // namespace

__global__ void downstream_make_secondary_vertices::downstream_make_secondary_vertices_views(
  downstream_make_secondary_vertices::Parameters parameters,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_nsvs)
{
  // Basic
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // svs
  // const auto total_number_of_svs = parameters.dev_offsets_downstream_secondary_vertices[number_of_events];
  const auto sv_offset = parameters.dev_offsets_downstream_secondary_vertices[event_number];
  const auto n_svs = parameters.dev_offsets_downstream_secondary_vertices[event_number + 1] - sv_offset;

  // Create views
  if (threadIdx.x == 0) {
    new (parameters.dev_sv_fit_results_view + event_number)
      Allen::Views::Physics::SecondaryVertices {parameters.dev_sv_fit_results,
                                                parameters.dev_offsets_downstream_secondary_vertices,
                                                event_number,
                                                number_of_events};
  }
  __syncthreads();

  for (unsigned sv_idx = threadIdx.x; sv_idx < n_svs; sv_idx += blockDim.x) {
    new (parameters.dev_two_track_composite_view + sv_offset + sv_idx)
      Allen::Views::Physics::CompositeParticle {parameters.dev_two_track_sv_track_pointers[sv_offset + sv_idx],
                                                parameters.dev_sv_fit_results_view + event_number,
                                                parameters.dev_downstream_secondary_vertices_pv[sv_offset + sv_idx],
                                                2u,
                                                sv_idx,
                                                parameters.dev_downstream_secondary_vertices_ip + sv_offset + sv_idx};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_two_track_composites_view + event_number) Allen::Views::Physics::CompositeParticles {
      parameters.dev_two_track_composite_view, parameters.dev_offsets_downstream_secondary_vertices, event_number};
  }
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_composites_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_two_track_composites_view, number_of_events};
    parameters.dev_multi_event_composites_ptr[0] = parameters.dev_multi_event_composites_view;
  }
  __syncthreads();

  //
  // Monitoring
  //
  if (threadIdx.x == 0) {
    dev_histogram_nsvs.increment(n_svs);
  }
}
__global__ void downstream_make_secondary_vertices::downstream_make_secondary_vertices(
  downstream_make_secondary_vertices::Parameters parameters)
{
  // Basic
  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const auto number_of_events = parameters.dev_number_of_events[0];

  // offsets
  const auto total_number_of_svs = parameters.dev_offsets_downstream_secondary_vertices[number_of_events];
  const auto sv_offset = parameters.dev_offsets_downstream_secondary_vertices[event_number];
  const auto n_svs = parameters.dev_offsets_downstream_secondary_vertices[event_number + 1] - sv_offset;

  // get downstream tracks
  const auto downstream_tracks = parameters.dev_multi_event_downstream_track_particles_view->container(event_number);

  // svs
  const auto svs = parameters.dev_downstream_secondary_vertices + VertexFit::max_svs * event_number;

  // Get pvs
  const auto pvs = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;
  const auto num_pvs = parameters.dev_number_of_multi_final_vertices[event_number];

  // Find PV and create views
  for (unsigned sv_idx = threadIdx.x; sv_idx < n_svs; sv_idx += blockDim.x) {
    const auto& sv = svs[sv_idx];

    // PV association
    Downstream::DownstreamHelpers::BestCandidateManager<unsigned> best_pv;
    for (unsigned pv_idx = 0; pv_idx < num_pvs; pv_idx++) {

      const auto pv = pvs[pv_idx].position;
      const auto& pvx = pv.x;
      const auto& pvy = pv.y;
      const auto& pvz = pv.z;

      const auto& z0 = sv.z;
      const auto& xA = sv.x;
      const auto& yA = sv.y;
      const auto txA = sv.px / sv.pz;
      const auto tyA = sv.px / sv.pz;

      const auto min_z = -(-pvz - pvx * txA - pvy * tyA + txA * xA + tyA * yA + z0) / (1.f + txA * txA + tyA * tyA);

      const auto dx = xA + txA * min_z - pvx;
      const auto dy = yA + tyA * min_z - pvz;
      const auto dz = min_z + z0 - pvz;

      const auto d2 = dx * dx + dy * dy + dz * dz;

      best_pv.add(pv_idx, d2);
    }

    const auto best_pv_ptr = best_pv.exist() ? pvs + best_pv.best() : nullptr;
    const auto best_ip = best_pv.exist() ? best_pv.score() : std::numeric_limits<float>::quiet_NaN();

    // Fill information
    parameters.dev_downstream_secondary_vertices_ip[sv_offset + sv_idx] = best_ip;
    parameters.dev_downstream_secondary_vertices_pv[sv_offset + sv_idx] = best_pv_ptr;

    fill_sv(parameters.dev_sv_fit_results, sv_offset + sv_idx, total_number_of_svs, sv);

    parameters.dev_two_track_sv_track_pointers[sv_offset + sv_idx] = {
      downstream_tracks.particle_pointer(sv.trk1), downstream_tracks.particle_pointer(sv.trk2), nullptr, nullptr};
  }
}
