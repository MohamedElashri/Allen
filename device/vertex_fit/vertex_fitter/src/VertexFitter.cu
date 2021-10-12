/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VertexFitter.cuh"

INSTANTIATE_ALGORITHM(VertexFit::fit_secondary_vertices_t)

void VertexFit::fit_secondary_vertices_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_consolidated_svs_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void VertexFit::fit_secondary_vertices_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(fit_secondary_vertices)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  if (runtime_options.fill_extra_host_buffers) {
    safe_assign_to_host_buffer<dev_consolidated_svs_t>(
      host_buffers.host_secondary_vertices, host_buffers.host_secondary_vertices_size, arguments, context);

    assign_to_host_buffer<dev_sv_offsets_t>(host_buffers.host_sv_offsets, arguments, context);
  }
}

__global__ void VertexFit::fit_secondary_vertices(VertexFit::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - sv_offset;
  const unsigned idx_offset = 10 * VertexFit::max_svs * event_number;
  const unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  const unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;
  const float* event_poca = parameters.dev_sv_poca + 3 * idx_offset;

  // Tracks.
  const auto long_track_particles = parameters.dev_long_track_particles[event_number];

  // Secondary vertices.
  VertexFit::TrackMVAVertex* event_secondary_vertices = parameters.dev_consolidated_svs + sv_offset;

  // Loop over svs.
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    VertexFit::TrackMVAVertex tmp_sv;
    tmp_sv.x = event_poca[3 * i_sv];
    tmp_sv.y = event_poca[3 * i_sv + 1];
    tmp_sv.z = event_poca[3 * i_sv + 2];
    tmp_sv.chi2 = -1;
    tmp_sv.minipchi2 = 0;
    auto i_track = event_svs_trk1_idx[i_sv];
    auto j_track = event_svs_trk2_idx[i_sv];
    const auto trackA = long_track_particles.particle(i_track);
    const auto trackB = long_track_particles.particle(j_track);

    // Do the fit.
    // TODO: In case doFit returns false, what should happen?
    doFit(trackA, trackB, tmp_sv);
    tmp_sv.trk1 = i_track;
    tmp_sv.trk2 = j_track;

      // Fill extra info.
      fill_extra_info(event_secondary_vertices[i_sv], trackA, trackB);
      // Handle events with no PV.
      if (trackA.pv() != nullptr) {
        const auto pv = trackA.ip_chi2() < trackB.ip_chi2() ? *trackA.pv() : *trackB.pv();
        fill_extra_pv_info(event_secondary_vertices[i_sv], pv, trackA, trackB, parameters.max_assoc_ipchi2);
      }
      else {
        // Set the minimum IP chi2 to 0 by default so this doesn't pass any displacement cuts.
        event_secondary_vertices[i_sv].minipchi2 = 0;
      }
    }
    else {
      // Set the minimum IP chi2 to 0 by default so this doesn't pass any displacement cuts.
      tmp_sv.minipchi2 = 0;
    }
    event_secondary_vertices[i_sv] = tmp_sv;
  }
}

void VertexFit::vertex_fit_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context&) const
{
  // Conditions to check
  bool chi2_always_positive = true;
  bool fdchi2_always_positive = true;
  bool ipchi2_always_positive = true;
  bool cov_always_posdef = true;

  const unsigned number_of_events = size<Parameters::dev_event_list_t>(arguments);
  const auto sv_offsets = make_vector<Parameters::dev_sv_offsets_t>(arguments);
  const auto event_list = make_vector<Parameters::dev_event_list_t>(arguments);
  const auto svs = make_vector<Parameters::dev_consolidated_svs_t>(arguments);

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