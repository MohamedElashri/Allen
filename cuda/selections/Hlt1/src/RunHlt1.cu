#include "RunHlt1.cuh"
#include "TrackMVALines.cuh"
#include "MuonLines.cuh"
#include "LineInfo.cuh"

#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::TrackMVAVertex* dev_consolidated_svs,
  const uint* dev_atomics_scifi,
  const uint* dev_sv_atomics,
  bool* dev_sel_results,
  uint* dev_sel_results_atomics)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  
  const uint* dev_sel_result_offsets = dev_sel_results_atomics + Hlt1::Hlt1Lines::End;
  
  // Tracks.
  const auto* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const auto* event_svs_offsets = dev_sv_atomics + number_of_events;
  const ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + event_tracks_offsets[event_number];
  const auto n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const VertexFit::TrackMVAVertex* event_vertices = dev_consolidated_svs + event_svs_offsets[event_number];
  const auto n_vertices_event = dev_sv_atomics[event_number];

  // Process 1-track lines.
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    bool* decs = dev_sel_results + dev_sel_result_offsets[i_line] + event_tracks_offsets[event_number];
    LineHandler<ParKalmanFilter::FittedTrack> handler {Hlt1::OneTrackSelections[i_line - Hlt1::startOneTrackLines]};
    handler(event_tracks, n_tracks_event, decs);
  }

  // Process 2-track lines.
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    bool* decs = dev_sel_results + dev_sel_result_offsets[i_line] + event_svs_offsets[event_number];
    LineHandler<VertexFit::TrackMVAVertex> handler {Hlt1::TwoTrackSelections[i_line - Hlt1::startTwoTrackLines]};
    handler(event_vertices, n_vertices_event, decs);
  }
  
}
