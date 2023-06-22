/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VertexFitter.cuh"

INSTANTIATE_ALGORITHM(VertexFit::fit_secondary_vertices_t)

void VertexFit::fit_secondary_vertices_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_nsvs = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "number_of_svs", "NSVs", {VertexFit::max_svs, 0, VertexFit::max_svs}}, {}};
#endif
}

__global__ void create_sv_views(VertexFit::Parameters parameters)
{
  // const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - offset;
  const auto pv_table = parameters.dev_sv_pv_tables[event_number];

  for (unsigned i = threadIdx.x; i < n_svs; i += blockDim.x) {
    const int i_pv = pv_table.pv(i);
    new (parameters.dev_two_track_composite_view + offset + i) Allen::Views::Physics::CompositeParticle {
      parameters.dev_two_track_sv_track_pointers[offset + i],
      parameters.dev_sv_fit_results_view + event_number,
      i_pv >= 0 ? parameters.dev_multi_final_vertices + PV::max_number_vertices * event_number + i_pv : nullptr,
      2,
      i};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_sv_fit_results_view + event_number) Allen::Views::Physics::SecondaryVertices {
      parameters.dev_sv_fit_results, parameters.dev_sv_offsets, event_number, number_of_events};

    new (parameters.dev_two_track_composites_view + event_number) Allen::Views::Physics::CompositeParticles {
      parameters.dev_two_track_composite_view, parameters.dev_sv_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_composites_view)
      Allen::Views::Physics::MultiEventCompositeParticles {parameters.dev_two_track_composites_view, number_of_events};
    parameters.dev_multi_event_composites_ptr[0] = parameters.dev_multi_event_composites_view;
  }
}

void VertexFit::fit_secondary_vertices_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_consolidated_svs_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_two_track_sv_track_pointers_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_two_track_composite_view_t>(arguments, first<host_number_of_svs_t>(arguments));
  set_size<dev_two_track_composites_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_composites_view_t>(arguments, 1);
  set_size<dev_multi_event_composites_ptr_t>(arguments, 1);
  set_size<dev_sv_pv_ip_t>(arguments, Associate::Consolidated::table_size(first<host_number_of_svs_t>(arguments)));
  set_size<dev_sv_pv_tables_t>(arguments, first<host_number_of_events_t>(arguments));
  // TODO: Clean this up.
  set_size<dev_sv_fit_results_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_sv_fit_results_t>(arguments, 14 * sizeof(uint32_t) * first<host_number_of_svs_t>(arguments));
}

void VertexFit::fit_secondary_vertices_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  auto dev_histogram_nsvs = make_device_buffer<unsigned>(arguments, VertexFit::max_svs);
  Allen::memset_async(dev_histogram_nsvs.data(), 0, dev_histogram_nsvs.size() * sizeof(unsigned), context);

  Allen::memset_async<dev_two_track_composite_view_t>(arguments, 0, context);

  global_function(fit_secondary_vertices)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, dev_histogram_nsvs.get());

  global_function(create_sv_views)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments, context, std::tuple {dev_histogram_nsvs.get(), histogram_nsvs, 0u, VertexFit::max_svs});
#endif
}

__host__ __device__ void fill_sv_fit_result(
  char* base_pointer,
  const VertexFit::TrackMVAVertex& sv,
  const unsigned index,
  const unsigned n_svs_total)
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
  fbase[nvrt * n_svs_total + ncov * index] = sv.cov00;
  fbase[nvrt * n_svs_total + ncov * index + 1] = sv.cov11;
  fbase[nvrt * n_svs_total + ncov * index + 2] = sv.cov10;
  fbase[nvrt * n_svs_total + ncov * index + 3] = sv.cov22;
  fbase[nvrt * n_svs_total + ncov * index + 4] = sv.cov21;
  fbase[nvrt * n_svs_total + ncov * index + 5] = sv.cov20;
  fbase[nvrt * n_svs_total + ncov * index + 6] = sv.chi2;
  // 4 + 4 - 3. Need to double check this because it doesn't seem right.
  reinterpret_cast<unsigned*>(fbase)[nvrt * n_svs_total + ncov * index + 7] = 5;
  return;
}

__global__ void VertexFit::fit_secondary_vertices(
  VertexFit::Parameters parameters,
  gsl::span<unsigned> dev_histogram_nsvs)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - sv_offset;
  const unsigned idx_offset = 10 * VertexFit::max_svs * event_number;
  const unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  const unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  const float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  if (n_svs < VertexFit::max_svs) ++dev_histogram_nsvs[n_svs];

  // Tracks.
  const auto long_track_particles = parameters.dev_long_track_particles->container(event_number);

  // Secondary vertices.
  VertexFit::TrackMVAVertex* event_secondary_vertices = parameters.dev_consolidated_svs + sv_offset;

  // Primary vertices.
  const unsigned n_pvs_event = *(parameters.dev_number_of_multi_final_vertices + event_number);
  Allen::device::span<PV::Vertex const> vertices {
    parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices, n_pvs_event};

  // SV -> PV table.
  const unsigned total_number_of_svs = parameters.dev_sv_offsets[number_of_events];
  // TODO: Don't use two different types of PV table.
  Associate::Consolidated::Table sv_pv_ip {parameters.dev_sv_pv_ip, total_number_of_svs};
  Associate::Consolidated::EventTable pv_table = sv_pv_ip.event_table(sv_offset, n_svs);
  parameters.dev_sv_pv_tables[event_number] =
    Allen::Views::Physics::PVTable {parameters.dev_sv_pv_ip, sv_offset, total_number_of_svs, n_svs};

  parameters.dev_sv_fit_results_view[event_number] = Allen::Views::Physics::SecondaryVertices {
    parameters.dev_sv_fit_results, parameters.dev_sv_offsets, event_number, number_of_events};

  // Loop over svs.
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    VertexFit::TrackMVAVertex tmp_sv;
    tmp_sv.x = event_poca[3 * i_sv];
    tmp_sv.y = event_poca[3 * i_sv + 1];
    tmp_sv.z = event_poca[3 * i_sv + 2];
    tmp_sv.chi2 = -1;
    tmp_sv.fdchi2 = -1;
    tmp_sv.minipchi2 = 0;
    auto i_track = event_svs_trk1_idx[i_sv];
    auto j_track = event_svs_trk2_idx[i_sv];

    const auto trackA = long_track_particles.particle(i_track);
    const auto trackB = long_track_particles.particle(j_track);

    parameters.dev_two_track_sv_track_pointers[sv_offset + i_sv] = {
      long_track_particles.particle_pointer(i_track), long_track_particles.particle_pointer(j_track), nullptr, nullptr};

    // Do the fit.
    doFit(trackA, trackB, tmp_sv);
    tmp_sv.trk1 = i_track;
    tmp_sv.trk2 = j_track;

    // Fill extra info.
    fill_extra_info(tmp_sv, trackA, trackB);
    if (n_pvs_event > 0) {
      pv_table.pv(i_sv) = fill_extra_pv_info(tmp_sv, vertices, trackA, trackB, parameters.max_assoc_ipchi2);
    }
    // Handle events with no PV.
    else {
      // Set the minimum IP chi2 to 0 by default so this doesn't pass any displacement cuts.
      pv_table.pv(i_sv) = -1;
      tmp_sv.minipchi2 = 0;
    }
    event_secondary_vertices[i_sv] = tmp_sv;

    // Fill the SV fit result.
    fill_sv_fit_result(parameters.dev_sv_fit_results, tmp_sv, sv_offset + i_sv, total_number_of_svs);
  }
}

void VertexFit::vertex_fit_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // Conditions to check
  bool chi2_always_positive = true;
  bool fdchi2_always_positive = true;
  bool ipchi2_always_positive = true;
  bool cov_always_posdef = true;

  const unsigned number_of_events = size<Parameters::dev_event_list_t>(arguments);
  const auto sv_offsets = make_host_buffer<Parameters::dev_sv_offsets_t>(arguments, context);
  const auto event_list = make_host_buffer<Parameters::dev_event_list_t>(arguments, context);
  const auto svs = make_host_buffer<Parameters::dev_consolidated_svs_t>(arguments, context);

  for (unsigned event_number = 0; event_number < number_of_events; event_number++) {
    const auto event_idx = event_list[event_number];
    const auto sv_offset = sv_offsets[event_idx];
    const auto n_svs = sv_offsets[event_idx + 1] - sv_offset;

    for (unsigned i_sv = 0; i_sv < n_svs; i_sv++) {
      const auto sv = svs[sv_offset + i_sv];
      chi2_always_positive &= sv.chi2 >= 0;
      fdchi2_always_positive &= sv.fdchi2 >= 0;
      ipchi2_always_positive &= sv.minipchi2 >= 0;

      // Check if the covariance matrix is positive definite using Sylvester's
      // criterion: https://en.wikipedia.org/wiki/Sylvester%27s_criterion
      const float det11 = sv.cov00;
      const float det22 = sv.cov00 * sv.cov11 - sv.cov10 * sv.cov10;
      const float det33 = sv.cov00 * sv.cov11 * sv.cov22 - sv.cov00 * sv.cov21 * sv.cov21 -
                          sv.cov10 * sv.cov10 * sv.cov22 + 2 * sv.cov10 * sv.cov20 * sv.cov21 -
                          sv.cov20 * sv.cov20 * sv.cov11;
      cov_always_posdef &= (det11 > 0) && (det22 > 0) && (det33 > 0);
    }
  }

  require(chi2_always_positive, "Require that the vertex chi2 is always >= 0");
  require(fdchi2_always_positive, "Require that the FD chi2 is always >= 0");
  require(ipchi2_always_positive, "Require that the IP chi2 is always >= 0");
  require(cov_always_posdef, "Require that the SV covariance matrix is always positive definite");
}
