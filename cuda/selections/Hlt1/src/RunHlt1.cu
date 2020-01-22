#include "RunHlt1.cuh"
#include "TrackMVALines.cuh"
#include "MuonLines.cuh"
#include "LineHandler.cuh"

__global__ void run_hlt1::run_hlt1(run_hlt1::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // Tracks.
  const auto* event_tracks_offsets = parameters.dev_atomics_scifi + number_of_events;
  const auto* event_svs_offsets = parameters.dev_sv_atomics + number_of_events;
  const ParKalmanFilter::FittedTrack* event_tracks = parameters.dev_kf_tracks + event_tracks_offsets[event_number];
  bool* event_one_track_results = parameters.dev_one_track_results + event_tracks_offsets[event_number];
  bool* event_single_muon_results = parameters.dev_single_muon_results + event_tracks_offsets[event_number];
  const auto n_tracks_event = parameters.dev_atomics_scifi[event_number];

  // Vertices.
  const VertexFit::TrackMVAVertex* event_vertices = parameters.dev_consolidated_svs + event_svs_offsets[event_number];
  bool* event_two_track_results = parameters.dev_two_track_results + event_svs_offsets[event_number];
  bool* event_disp_dimuon_results = parameters.dev_disp_dimuon_results + event_svs_offsets[event_number];
  bool* event_high_mass_dimuon_results = parameters.dev_high_mass_dimuon_results + event_svs_offsets[event_number];
  bool* event_dimuon_soft_results = parameters.dev_dimuon_soft_results + event_svs_offsets[event_number];

  const auto n_vertices_event = parameters.dev_sv_atomics[event_number];

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
