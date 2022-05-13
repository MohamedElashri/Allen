#include "HeavyIonEventLine.cuh"

INSTANTIATE_LINE(heavy_ion_event_line::heavy_ion_event_line_t, heavy_ion_event_line::Parameters)

__device__ std::tuple<const int, const int, const int, const int, const float>
heavy_ion_event_line::heavy_ion_event_line_t::get_input(
    const Parameters& parameters,
    const unsigned event_number,
    const unsigned)
{
  // Count VELO tracks
  int n_velo_tracks_PbPb = 0;
  int n_velo_tracks_SMOG = 0;
  const auto velo_tracks = parameters.dev_velo_tracks[event_number];
  const auto velo_states = parameters.dev_velo_states[event_number];
  for (unsigned i_track = 0; i_track < velo_tracks.size(); i_track++) {
    const auto velo_track = velo_tracks.track(i_track);
    const auto velo_state = velo_track.state(velo_states);
    if (velo_state.z() < -300.f) n_velo_tracks_SMOG++;
    else n_velo_tracks_PbPb++;
  }

  // Count PVs
  int n_pvs_PbPb = 0;
  int n_pvs_SMOG = 0;
  Allen::device::span<PV::Vertex const> pvs {parameters.dev_pvs + event_number * PV::max_number_vertices,
                                             parameters.dev_number_of_pvs[event_number]};
  for (unsigned i_vrt = 0; i_vrt < pvs.size(); i_vrt++) {
    const auto pv = pvs[i_vrt];
    if (pv.position.z < -300.f) n_pvs_SMOG++;
    else n_pvs_PbPb++;
  }

  // Calculate ECAL energy

  // TODO: This is a placeholder for now. Currently, this loop calculates the
  // sum of ECAL ADC counts, which isn't meaningful without the gain and
  // pedestal for each cell. The total ECAL energy will need to be calculated in
  // a separate algorithm where the ECAL geometry is accessible.
  float ecal_adc = 0.f;
  const auto digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  const auto n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
  const auto event_calo_digits = parameters.dev_ecal_digits + digits_offset;
  for (unsigned i_digit = 0; i_digit < n_digits; i_digit++) {
    const auto digit = event_calo_digits[i_digit];
    ecal_adc += digit.adc;
  }

  return std::forward_as_tuple(n_velo_tracks_PbPb, n_velo_tracks_SMOG, n_pvs_PbPb, n_pvs_SMOG, ecal_adc);
}

__device__ bool heavy_ion_event_line::heavy_ion_event_line_t::select(
  const Parameters& parameters, 
  std::tuple<const int, const int, const int, const int, const float>input)
{
  const auto n_velo_tracks_PbPb = std::get<0>(input);
  const auto n_velo_tracks_SMOG = std::get<1>(input);
  const auto n_pvs_PbPb = std::get<2>(input);
  const auto n_pvs_SMOG = std::get<3>(input);
  const auto ecal_adc = std::get<4>(input);

  bool dec = n_velo_tracks_PbPb >= parameters.min_velo_tracks_PbPb;
  dec &= n_velo_tracks_PbPb <= parameters.max_velo_tracks_PbPb || parameters.max_velo_tracks_PbPb < 0;
  dec &= n_velo_tracks_SMOG >= parameters.min_velo_tracks_SMOG;
  dec &= n_velo_tracks_SMOG <= parameters.max_velo_tracks_SMOG || parameters.max_velo_tracks_SMOG < 0;

  dec &= n_pvs_PbPb >= parameters.min_pvs_PbPb;
  dec &= n_pvs_PbPb <= parameters.max_pvs_PbPb || parameters.max_pvs_PbPb < 0;
  dec &= n_pvs_SMOG >= parameters.min_pvs_SMOG;
  dec &= n_pvs_SMOG <= parameters.max_pvs_SMOG || parameters.max_pvs_SMOG < 0;
  
  dec &= ecal_adc >= parameters.min_ecal_e;
  dec &= ecal_adc <= parameters.max_ecal_e || parameters.max_ecal_e < 0;

  return dec;
}