#include "RunHlt1.cuh"
#include "TrackMVALines.cuh"

#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsKalmanFilter.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsSelections.cuh"
#include "ArgumentsVertex.cuh"

__global__ void run_hlt1(
  const ParKalmanFilter::FittedTrack* dev_kf_tracks,
  const VertexFit::Vertex* dev_secondary_vertices,
  const int* dev_atomics_scifi,
  const uint* dev_sv_offsets,
  bool* dev_one_track_results,
  bool* dev_two_track_results)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Tracks.
  const int* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + event_tracks_offsets[event_number];
  bool* event_one_track_results = dev_one_track_results + event_tracks_offsets[event_number];
  const int n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const VertexFit::Vertex* event_vertices = dev_secondary_vertices + dev_sv_offsets[event_number];
  bool* event_two_track_results = dev_two_track_results + dev_sv_offsets[event_number];
  const int n_vertices_event = dev_sv_offsets[event_number + 1] - dev_sv_offsets[event_number];
  
  LineHandler<ParKalmanFilter::FittedTrack> oneTrackHandler(TrackMVALines::OneTrackMVA);
  LineHandler<VertexFit::Vertex> twoTrackHandler(TrackMVALines::TwoTrackMVA);

  oneTrackHandler(
    event_tracks,
    n_tracks_event,
    event_one_track_results);
  
  twoTrackHandler(
    event_vertices,
    n_vertices_event,
    event_two_track_results);
}
