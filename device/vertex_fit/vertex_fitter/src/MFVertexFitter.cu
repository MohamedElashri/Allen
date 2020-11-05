/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VertexFitter.cuh"
#include "MFVertexFitter.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanDefinitions.cuh"

void MFVertexFit::fit_mf_vertices_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_mf_svs_t>(arguments, first<host_number_of_mf_svs_t>(arguments));
}

void MFVertexFit::fit_mf_vertices_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  initialize<dev_mf_svs_t>(arguments, 0, context);

  global_function(fit_mf_vertices)(dim3(first<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  safe_assign_to_host_buffer<dev_mf_svs_t>(
    host_buffers.host_mf_secondary_vertices, host_buffers.host_mf_secondary_vertices_size, arguments, stream);

  assign_to_host_buffer<dev_mf_sv_offsets_t>(host_buffers.host_mf_sv_offsets, arguments, stream);
}

__global__ void MFVertexFit::fit_mf_vertices(MFVertexFit::Parameters parameters)
{
  const unsigned muon_filtered_event = blockIdx.x;
  const unsigned event_number = parameters.dev_event_list_mf[muon_filtered_event];
  const unsigned sv_offset = parameters.dev_mf_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_mf_sv_offsets[event_number + 1] - sv_offset;
  const unsigned idx_offset = 10 * VertexFit::max_svs * muon_filtered_event;
  const unsigned* event_svs_kf_idx = parameters.dev_svs_kf_idx + idx_offset;
  const unsigned* event_svs_mf_idx = parameters.dev_svs_mf_idx + idx_offset;

  // KF tracks.
  const unsigned kf_offset = parameters.dev_offsets_forward_tracks[event_number];
  const ParKalmanFilter::FittedTrack* kf_tracks = parameters.dev_kf_tracks + kf_offset;

  // MF tracks.
  const unsigned mf_offset = parameters.dev_mf_track_offsets[event_number];
  const ParKalmanFilter::FittedTrack* mf_tracks = parameters.dev_mf_tracks + mf_offset;

  // Vertices.
  VertexFit::TrackMVAVertex* event_mf_svs = parameters.dev_mf_svs + sv_offset;

  // Loop over svs.
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_mf_svs[i_sv].chi2 = -1;
    event_mf_svs[i_sv].minipchi2 = 0;
    auto i_track = event_svs_kf_idx[i_sv];
    auto j_track = event_svs_mf_idx[i_sv];
    const ParKalmanFilter::FittedTrack trackA = kf_tracks[i_track];
    const ParKalmanFilter::FittedTrack trackB = mf_tracks[i_track];

    // Do the fit.
    doFit(trackA, trackB, event_mf_svs[i_sv]);
    event_mf_svs[i_sv].trk1 = i_track;
    event_mf_svs[i_sv].trk2 = j_track;

    // Fill extra info. Don't worry about PVs.
    fill_extra_info(event_mf_svs[i_sv], trackA, trackB);
  }
}
