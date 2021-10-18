/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "BremRecovery.cuh"
#include "EcalScan.cuh"

INSTANTIATE_ALGORITHM(brem_recovery::brem_recovery_t)

void brem_recovery::brem_recovery_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_brem_E_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_brem_ET_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_brem_inECALacc_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_brem_ecal_digits_size_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
  set_size<dev_brem_ecal_digits_t>(arguments, first<host_number_of_reconstructed_velo_tracks_t>(arguments));
}

void brem_recovery::brem_recovery_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  Allen::Context const& context) const
{
  initialize<dev_brem_E_t>(arguments, 0, context);
  initialize<dev_brem_ET_t>(arguments, 0, context);
  initialize<dev_brem_inECALacc_t>(arguments, 0, context);
  initialize<dev_brem_ecal_digits_size_t>(arguments, 0, context);
  initialize<dev_brem_ecal_digits_t>(arguments, 0, context);

  global_function(brem_recovery)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_ecal_geometry);
}

__global__ void brem_recovery::brem_recovery(brem_recovery::Parameters parameters, const char* raw_ecal_geometry)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // Create velo tracks.
  Velo::Consolidated::Tracks const velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Get velo kalman beamline states
  Velo::Consolidated::ConstStates velo_Kalman_beamline_states {parameters.dev_velo_kalman_beamline_states,
                                                               velo_tracks.total_number_of_tracks()};

  // Get ECAL digits
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  auto const* digits = parameters.dev_ecal_digits + digits_offset;

  // Loop over the velo tracks in parallel to find brem cluster
  for (unsigned track_index = threadIdx.x; track_index < velo_tracks.number_of_tracks(event_number);
       track_index += blockDim.x) {
    auto track_index_with_offset = track_index + velo_tracks.tracks_offset(event_number);

    // VELO state
    const MiniState velo_state = velo_Kalman_beamline_states.get(track_index_with_offset);

    // Get z positions of intersection of the track and front, showermax and back planes
    float z_front = ecal_geometry.getZFromTrackToCaloplaneIntersection(velo_state, 0);
    float z_showermax = ecal_geometry.getZFromTrackToCaloplaneIntersection(velo_state, 1);
    float z_back = ecal_geometry.getZFromTrackToCaloplaneIntersection(velo_state, 2);

    // Delta z traversed inside the ECAL
    float ecal_delta_z = z_back - z_front;

    // Define 4 z positions along the track inside the ECAL
    constexpr unsigned N_ecal_positions = 4;
    const float ecal_positions[N_ecal_positions] = {z_front, z_showermax, z_front + 0.5f * ecal_delta_z, z_back};

    std::array<unsigned, N_ecal_positions> digit_indices = {9999, 9999, 9999, 9999};
    unsigned N_matched_digits {0};
    bool inAcc = false;
    float sum_cell_E {0.f};

    // Loop over four z positions in the ECAL to check which cell is traversed by the track
    ecal_scan(
      N_ecal_positions,
      ecal_positions,
      velo_state,
      ecal_geometry,
      inAcc,
      digits,
      N_matched_digits,
      sum_cell_E,
      digit_indices);

    parameters.dev_brem_E[track_index_with_offset] = sum_cell_E;
    parameters.dev_brem_ET[track_index_with_offset] =
      sum_cell_E * sqrtf(
                     (velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty) /
                     (velo_state.tx * velo_state.tx + velo_state.ty * velo_state.ty + 1.f));
    parameters.dev_brem_inECALacc[track_index_with_offset] = inAcc;
    parameters.dev_brem_ecal_digits[track_index_with_offset] = digit_indices;
    parameters.dev_brem_ecal_digits_size[track_index_with_offset] = N_matched_digits;
  }
}