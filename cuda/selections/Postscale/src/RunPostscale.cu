#include "RawBanksDefinitions.cuh"

#include "RunPostscale.cuh"

__device__ uint32_t postscale::mix( uint32_t state )
{
  state += ( state << 16 );
  state ^= ( state >> 13 );
  state += ( state << 4 );
  state ^= ( state >> 7 );
  state += ( state << 10 );
  state ^= ( state >> 5 );
  state += ( state << 8 );
  state ^= ( state >> 16 );
  return state;

}

__device__ uint32_t postscale::mix32( uint32_t state, uint32_t extra )
{
  return postscale::mix( state + extra );
}

__device__ uint32_t postscale::mix64( uint32_t state, uint32_t extra_hi, uint32_t extra_lo )
{
  state           = mix32( state, extra_lo );
  return postscale::mix32( state, extra_hi );
}

__device__ void DeterministicPostscaler::operator()(
  const int n_candidates,
  bool* results,
  const uint32_t run_number,
  const uint32_t evt_number_hi,
  const uint32_t evt_number_lo,
  const uint32_t gps_time_hi,
  const uint32_t gps_time_lo)
{
  if (accept_threshold == std::numeric_limits<uint32_t>::max()) return;

  auto x = postscale::mix64( postscale::mix32( postscale::mix64( initial_value, gps_time_hi, gps_time_lo ), run_number ), evt_number_hi, evt_number_lo );

  if (x >= accept_threshold) {
    for ( auto i_cand = 0; i_cand < n_candidates; ++i_cand ) {
      results[i_cand] = 0;
    }
  }
}

__global__ void run_postscale(
    char* dev_odin_raw_input,
    uint* dev_odin_raw_input_offsets,
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
  bool* event_one_track_results = dev_one_track_results + event_tracks_offsets[event_number];
  bool* event_single_muon_results = dev_single_muon_results + event_tracks_offsets[event_number];
  const auto n_tracks_event = dev_atomics_scifi[event_number];

  // Vertices.
  bool* event_two_track_results = dev_two_track_results + dev_sv_offsets[event_number];
  bool* event_disp_dimuon_results = dev_disp_dimuon_results + dev_sv_offsets[event_number];
  bool* event_high_mass_dimuon_results = dev_high_mass_dimuon_results + dev_sv_offsets[event_number];
  bool* event_dimuon_soft_results = dev_dimuon_soft_results + dev_sv_offsets[event_number];

  const auto n_vertices_event = dev_sv_offsets[event_number + 1] - dev_sv_offsets[event_number];

  DeterministicPostscaler ps_one_track(Hlt1::OneTrackMVA, postscale::factor_one_track);
  DeterministicPostscaler ps_single_muon(Hlt1::SingleMuon, postscale::factor_single_muon);
  DeterministicPostscaler ps_two_tracks(Hlt1::TwoTrackMVA, postscale::factor_two_tracks);
  DeterministicPostscaler ps_disp_dimuon(Hlt1::DisplacedDiMuon, postscale::factor_disp_dimuon);
  DeterministicPostscaler ps_high_mass_dimuon(Hlt1::HighMassDiMuon, postscale::factor_high_mass_dimuon);
  DeterministicPostscaler ps_dimuon_soft(Hlt1::SoftDiMuon, postscale::factor_dimuon_soft);

  const uint hdr_size(8);
  const unsigned int* odinData = reinterpret_cast<const uint*>(dev_odin_raw_input + dev_odin_raw_input_offsets[event_number] + hdr_size);

  uint32_t run_no = odinData[LHCb::ODIN::Data::RunNumber];
  uint32_t evt_hi = odinData[LHCb::ODIN::Data::L0EventIDHi];
  uint32_t evt_lo = odinData[LHCb::ODIN::Data::L0EventIDLo];
  uint32_t gps_hi = odinData[LHCb::ODIN::Data::GPSTimeHi];
  uint32_t gps_lo = odinData[LHCb::ODIN::Data::GPSTimeLo];

  // One track lines.
  ps_one_track(n_tracks_event, event_one_track_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);

  ps_single_muon(n_tracks_event, event_single_muon_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);

  // Two track lines.
  ps_two_tracks(n_vertices_event, event_two_track_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);

  ps_disp_dimuon(n_vertices_event, event_disp_dimuon_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);

  ps_high_mass_dimuon(n_vertices_event, event_high_mass_dimuon_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);
  ps_dimuon_soft(n_vertices_event, event_dimuon_soft_results, run_no, evt_hi, evt_lo, gps_hi, gps_lo);

}
