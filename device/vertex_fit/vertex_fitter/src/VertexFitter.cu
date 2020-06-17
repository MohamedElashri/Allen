#include "VertexFitter.cuh"

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
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(fit_secondary_vertices)(
    dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(arguments);

  safe_assign_to_host_buffer<dev_consolidated_svs_t>(
    host_buffers.host_secondary_vertices, host_buffers.host_secondary_vertices_size, arguments, cuda_stream);

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_sv_offsets,
    data<dev_sv_offsets_t>(arguments),
    size<dev_sv_offsets_t>(arguments),
    cudaMemcpyDeviceToHost,
    cuda_stream));
}

__global__ void VertexFit::fit_secondary_vertices(VertexFit::Parameters parameters)
{
  const unsigned number_of_events = gridDim.x;
  const unsigned event_number = blockIdx.x;
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs = parameters.dev_sv_offsets[event_number + 1] - sv_offset;
  const unsigned idx_offset = 10 * VertexFit::max_svs * event_number;
  const unsigned* event_svs_trk1_idx = parameters.dev_svs_trk1_idx + idx_offset;
  const unsigned* event_svs_trk2_idx = parameters.dev_svs_trk2_idx + idx_offset;

  // Consolidated SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {
    parameters.dev_atomics_scifi,
    parameters.dev_scifi_track_hit_number,
    parameters.dev_scifi_qop,
    parameters.dev_scifi_states,
    parameters.dev_scifi_track_ut_indices,
    event_number,
    number_of_events};
  const unsigned event_tracks_offset = scifi_tracks.tracks_offset(event_number);

  // Track-PV association table.
  Associate::Consolidated::ConstTable kalman_pv_ipchi2 {
    parameters.dev_kalman_pv_ipchi2, scifi_tracks.total_number_of_tracks()};
  const auto pv_table = kalman_pv_ipchi2.event_table(scifi_tracks, event_number);

  // Kalman fitted tracks.
  const ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + event_tracks_offset;

  // Primary vertices.
  const unsigned n_pvs_event = *(parameters.dev_number_of_multi_fit_vertices + event_number);
  cuda::span<PV::Vertex const> vertices {
    parameters.dev_multi_fit_vertices + event_number * PV::max_number_vertices, n_pvs_event};

  // Secondary vertices.
  VertexFit::TrackMVAVertex* event_secondary_vertices = parameters.dev_consolidated_svs + sv_offset;

  // Loop over svs.
  for (unsigned i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_secondary_vertices[i_sv].chi2 = -1;
    event_secondary_vertices[i_sv].minipchi2 = 0;
    auto i_track = event_svs_trk1_idx[i_sv];
    auto j_track = event_svs_trk2_idx[i_sv];
    const ParKalmanFilter::FittedTrack trackA = event_tracks[i_track];
    const ParKalmanFilter::FittedTrack trackB = event_tracks[j_track];

    // Do the fit.
    doFit(trackA, trackB, event_secondary_vertices[i_sv]);
    event_secondary_vertices[i_sv].trk1 = i_track;
    event_secondary_vertices[i_sv].trk2 = j_track;

    // Fill extra info.
    fill_extra_info(event_secondary_vertices[i_sv], trackA, trackB);
    if (n_pvs_event > 0) {
      int ipv = pv_table.value(i_track) < pv_table.value(j_track) ? pv_table.pv(i_track) : pv_table.pv(j_track);
      auto pv = vertices[ipv];
      fill_extra_pv_info(event_secondary_vertices[i_sv], pv, trackA, trackB, parameters.max_assoc_ipchi2);
    }
    else {
      // Set the minimum IP chi2 to 0 by default so this doesn't pass any displacement cuts.
      event_secondary_vertices[i_sv].minipchi2 = 0;
    }
  }
}
