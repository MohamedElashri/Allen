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

__device__ uint32_t postscale::mix64( uint32_t state, uint64_t extra )
{
  constexpr auto mask = ( ( ~uint64_t{0} ) >> 32 );
  state               = mix32( state, uint32_t( extra & mask ) );
  return postscale::mix32( state, uint32_t( ( extra >> 32 ) & mask ) );
}

__device__ void DeterministicPostscaler::operator()(const int n_candidates, bool* results, const LHCb::ODIN& odin)
{
  if (accept_threshold == std::numeric_limits<uint32_t>::max()) return;

  auto x = postscale::mix64( postscale::mix32( postscale::mix64( initial_value, odin.gps_time ), odin.run_number ), odin.event_number );

  if (x >= accept_threshold) {
    for ( auto i_cand = 0; i_cand < n_candidates; ++i_cand ) {
      results[i_cand] = 0;
    }
  }
}

__global__ void run_postscale(
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

  //TODO fake ODIN
  LHCb::ODIN odin;

  // One track lines.
  ps_one_track(n_tracks_event, event_one_track_results, odin);

  ps_single_muon(n_tracks_event, event_single_muon_results, odin);

  // Two track lines.
  ps_two_tracks(n_vertices_event, event_two_track_results, odin);

  ps_disp_dimuon(n_vertices_event, event_disp_dimuon_results, odin);

  ps_high_mass_dimuon(n_vertices_event, event_high_mass_dimuon_results, odin);
  ps_dimuon_soft(n_vertices_event, event_dimuon_soft_results, odin);

}
