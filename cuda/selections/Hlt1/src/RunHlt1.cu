#include "RunHlt1.cuh"
#include "TrackMVALines.cuh"
#include "MuonLines.cuh"
#include "LineHandler.cuh"

void run_hlt1_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_one_track_results>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_two_track_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_single_muon_results>(host_buffers.host_number_of_reconstructed_scifi_tracks[0]);
  arguments.set_size<dev_disp_dimuon_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_high_mass_dimuon_results>(host_buffers.host_number_of_svs[0]);
  arguments.set_size<dev_dimuon_soft_results>(host_buffers.host_number_of_svs[0]);
}

void run_hlt1_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_kf_tracks>(),
    arguments.offset<dev_secondary_vertices>(),
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_sv_offsets>(),
    arguments.offset<dev_one_track_results>(),
    arguments.offset<dev_two_track_results>(),
    arguments.offset<dev_single_muon_results>(),
    arguments.offset<dev_disp_dimuon_results>(),
    arguments.offset<dev_high_mass_dimuon_results>(),
    arguments.offset<dev_dimuon_soft_results>());

  if (runtime_options.do_check) {
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_one_track_decisions,
      arguments.offset<dev_one_track_results>(),
      arguments.size<dev_one_track_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_two_track_decisions,
      arguments.offset<dev_two_track_results>(),
      arguments.size<dev_two_track_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_single_muon_decisions,
      arguments.offset<dev_single_muon_results>(),
      arguments.size<dev_single_muon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_disp_dimuon_decisions,
      arguments.offset<dev_disp_dimuon_results>(),
      arguments.size<dev_disp_dimuon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_high_mass_dimuon_decisions,
      arguments.offset<dev_high_mass_dimuon_results>(),
      arguments.size<dev_high_mass_dimuon_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream));
    cudaCheck(cudaMemcpyAsync(
      host_buffers.host_dimuon_soft_decisions,
      arguments.offset<dev_dimuon_soft_results>(),
      arguments.size<dev_dimuon_soft_results>(),
      cudaMemcpyDeviceToHost,
      cuda_stream)); 
  }
}

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_secondary_vertices,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results,
  bool* dev_single_muon_results,
  bool* dev_disp_dimuon_results,
  bool* dev_high_mass_dimuon_results,
  bool* dev_dimuon_soft_results)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Tracks.
  const auto* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + event_tracks_offsets[event_number];
  bool* event_one_track_results = dev_one_track_results + event_tracks_offsets[event_number];
  bool* event_single_muon_results = dev_single_muon_results + event_tracks_offsets[event_number];
  const auto n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const VertexFit::TrackMVAVertex* event_vertices = dev_secondary_vertices + dev_sv_offsets[event_number];
  bool* event_two_track_results = dev_two_track_results + dev_sv_offsets[event_number];
  bool* event_disp_dimuon_results = dev_disp_dimuon_results + dev_sv_offsets[event_number];
  bool* event_high_mass_dimuon_results = dev_high_mass_dimuon_results + dev_sv_offsets[event_number];
  bool* event_dimuon_soft_results = dev_dimuon_soft_results + dev_sv_offsets[event_number];

  const auto n_vertices_event = dev_sv_offsets[event_number + 1] - dev_sv_offsets[event_number];

  LineHandler<ParKalmanFilter::FittedTrack> oneTrackHandler {TrackMVALines::OneTrackMVA};
  LineHandler<VertexFit::TrackMVAVertex> twoTrackHandler {TrackMVALines::TwoTrackMVA};
  LineHandler<ParKalmanFilter::FittedTrack> singleMuonHandler {MuonLines::SingleMuon};
  LineHandler<VertexFit::TrackMVAVertex> dispDiMuonHandler {MuonLines::DisplacedDiMuon};
  LineHandler<VertexFit::TrackMVAVertex> highMassDiMuonHandler {MuonLines::HighMassDiMuon};
  LineHandler<VertexFit::TrackMVAVertex> diMuonSoftHandler {MuonLines::DiMuonSoft};

  // One track lines.
  oneTrackHandler(event_tracks, n_tracks_event, event_one_track_results);

  singleMuonHandler(event_tracks, n_tracks_event, event_single_muon_results);

  // Two track lines.
  twoTrackHandler(event_vertices, n_vertices_event, event_two_track_results);

  dispDiMuonHandler(event_vertices, n_vertices_event, event_disp_dimuon_results);

  highMassDiMuonHandler(event_vertices, n_vertices_event, event_high_mass_dimuon_results);
  diMuonSoftHandler(event_vertices, n_vertices_event, event_dimuon_soft_results);

}
