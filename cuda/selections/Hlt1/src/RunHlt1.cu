#include "RunHlt1.cuh"
#include "RawBanksDefinitions.cuh"
#include "TrackMVALines.cuh"
#include "MuonLines.cuh"

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

  const uint total_tracks = dev_atomics_scifi[2 * number_of_events];
  const uint total_svs = dev_sv_atomics[2 * number_of_events];
  
  const uint* dev_sel_result_offsets = dev_sel_results_atomics + Hlt1::Hlt1Lines::End;
  
  // Tracks.
  const auto* event_tracks_offsets = dev_atomics_scifi + number_of_events;
  const auto* event_svs_offsets = dev_sv_atomics + number_of_events;
  const ParKalmanFilter::FittedTrack* event_tracks = dev_kf_tracks + event_tracks_offsets[event_number];
  bool* event_one_track_results = dev_sel_results +
    dev_sel_result_offsets[Hlt1::Hlt1Lines::OneTrackMVA] + event_tracks_offsets[event_number];
  bool* event_single_muon_results = dev_sel_results +
    dev_sel_result_offsets[Hlt1::Hlt1Lines::SingleMuon] + event_tracks_offsets[event_number];
  const auto n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  const VertexFit::TrackMVAVertex* event_vertices = dev_consolidated_svs + event_svs_offsets[event_number];
  bool* event_two_track_results = dev_sel_results + 
    dev_sel_result_offsets[Hlt1::Hlt1Lines::TwoTrackMVA] + event_svs_offsets[event_number];
  bool* event_disp_dimuon_results = dev_sel_results + 
    dev_sel_result_offsets[Hlt1::Hlt1Lines::DisplacedDiMuon] + event_svs_offsets[event_number];
  bool* event_high_mass_dimuon_results = dev_sel_results + 
    dev_sel_result_offsets[Hlt1::Hlt1Lines::HighMassDiMuon] + event_svs_offsets[event_number];
  bool* event_dimuon_soft_results = dev_sel_results + 
    dev_sel_result_offsets[Hlt1::Hlt1Lines::SoftDiMuon] + event_svs_offsets[event_number];
  const auto n_vertices_event = dev_sv_atomics[event_number];
  
  LineHandler<ParKalmanFilter::FittedTrack> oneTrackHandler {TrackMVALines::OneTrackMVA};
  LineHandler<ParKalmanFilter::FittedTrack> singleMuonHandler {MuonLines::SingleMuon};
  LineHandler<VertexFit::TrackMVAVertex> twoTrackHandler {TrackMVALines::TwoTrackMVA};
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
