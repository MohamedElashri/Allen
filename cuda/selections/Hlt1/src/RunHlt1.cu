#include "RunHlt1.cuh"
#include "TrackMVALines.cuh"
#include "MuonLines.cuh"
#include "LineHandler.cuh"
#include "LineInfo.cuh"

__global__ void run_hlt1::run_hlt1(run_hlt1::Parameters parameters)
{
  const uint event_number = blockIdx.x;
  
  // Tracks.
  const ParKalmanFilter::FittedTrack* event_tracks =
    parameters.dev_kf_tracks + parameters.dev_offsets_forward_tracks[event_number];
  const auto n_tracks_event =
    parameters.dev_offsets_forward_tracks[event_number + 1] - parameters.dev_offsets_forward_tracks[event_number];

  // Vertices.
  const VertexFit::TrackMVAVertex* event_vertices =
    parameters.dev_consolidated_svs + parameters.dev_sv_offsets[event_number];
  
  const auto n_vertices_event = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];

  // Process 1-track lines.
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + parameters.dev_offsets_forward_tracks[event_number];
    LineHandler<ParKalmanFilter::FittedTrack> handler {Hlt1::OneTrackSelections[i_line - Hlt1::startOneTrackLines]};
    handler(event_tracks, n_tracks_event, decs);
  }

  // Process 2-track lines.
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    bool* decs = parameters.dev_sel_results + parameters.dev_sel_results_offsets[i_line] + parameters.dev_sv_offsets[event_number];
    LineHandler<VertexFit::TrackMVAVertex> handler {Hlt1::TwoTrackSelections[i_line - Hlt1::startTwoTrackLines]};
    handler(event_vertices, n_vertices_event, decs);
  }
}
