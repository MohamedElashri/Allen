/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "TrackDigitSelectiveMatching.cuh"
#include "EcalScan.cuh"

INSTANTIATE_ALGORITHM(track_digit_selective_matching::track_digit_selective_matching_t)

void track_digit_selective_matching::track_digit_selective_matching_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_matched_ecal_energy_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_matched_ecal_digits_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_matched_ecal_digits_size_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_track_inEcalAcc_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_track_Eop_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_track_isElectron_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void track_digit_selective_matching::track_digit_selective_matching_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  Allen::Context const& context) const
{
  Allen::memset_async<dev_matched_ecal_energy_t>(arguments, 0, context);
  Allen::memset_async<dev_matched_ecal_digits_t>(arguments, 0, context);
  Allen::memset_async<dev_matched_ecal_digits_size_t>(arguments, 0, context);
  Allen::memset_async<dev_track_inEcalAcc_t>(arguments, 0, context);
  Allen::memset_async<dev_track_Eop_t>(arguments, 0, context);
  Allen::memset_async<dev_track_isElectron_t>(arguments, 0, context);

  global_function(track_digit_selective_matching)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments, constants.dev_ecal_geometry);
}

__global__ void track_digit_selective_matching::track_digit_selective_matching(
  track_digit_selective_matching::Parameters parameters,
  const char* raw_ecal_geometry)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // Long tracks.
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);

  const unsigned n_long_tracks = long_tracks.size();
  const unsigned event_offset = long_tracks.offset();

  // Get ECAL digits
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  auto const* digits = parameters.dev_ecal_digits + digits_offset;

  // Loop over the long tracks in parallel
  for (unsigned track_index = threadIdx.x; track_index < n_long_tracks; track_index += blockDim.x) {
    const auto long_track = long_tracks.track(track_index);
    const auto scifi_track = long_track.track_segment<Allen::Views::Physics::Track::segment::scifi>();
    const auto scifi_track_id = scifi_track.track_index();
    // SciFi state
    const auto& scifi_state = parameters.dev_scifi_states[event_offset + track_index];

    // Get z positions of intersection of the track and front, showermax and back planes
    float z_front = ecal_geometry.getZFromTrackToCaloplaneIntersection(scifi_state, 0);
    float z_showermax = ecal_geometry.getZFromTrackToCaloplaneIntersection(scifi_state, 1);
    float z_back = ecal_geometry.getZFromTrackToCaloplaneIntersection(scifi_state, 2);

    // Delta z traversed inside the ECAL
    float ecal_delta_z = z_back - z_front;

    // Define 6 z positions along the track inside the ECAL
    constexpr unsigned N_ecal_positions = 6;
    const float ecal_positions[N_ecal_positions] = {z_front,
                                                    z_showermax,
                                                    z_front + 0.25f * ecal_delta_z,
                                                    z_front + 0.5f * ecal_delta_z,
                                                    z_front + 0.75f * ecal_delta_z,
                                                    z_back};

    std::array<unsigned, N_ecal_positions> digit_indices = {9999, 9999, 9999, 9999, 9999, 9999};
    unsigned N_matched_digits {0};
    bool inAcc = false;
    float sum_cell_E {0.f};

    // Loop over six z positions in the ECAL to check which cell is traversed by the track
    ecal_scan(
      N_ecal_positions,
      ecal_positions,
      scifi_state,
      ecal_geometry,
      inAcc,
      digits,
      N_matched_digits,
      sum_cell_E,
      digit_indices);

    parameters.dev_matched_ecal_energy[track_index + event_offset] = sum_cell_E;
    parameters.dev_matched_ecal_digits[track_index + event_offset] = digit_indices;
    parameters.dev_matched_ecal_digits_size[track_index + event_offset] = N_matched_digits;
    parameters.dev_track_inEcalAcc[track_index + event_offset] = inAcc;
    parameters.dev_track_Eop[track_index + event_offset] = sum_cell_E * fabsf(long_track.qop());
    parameters.dev_track_isElectron[track_index + event_offset] =
      parameters.dev_track_Eop[track_index + event_offset] > 0.7f;
  }
}
