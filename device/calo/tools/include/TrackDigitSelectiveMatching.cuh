/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Datatype.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "ParticleTypes.cuh"

namespace track_digit_selective_matching {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    // SciFi tracks
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    // DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    // Calo digits
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_of_digits;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    // Outputs
    DEVICE_OUTPUT(dev_matched_ecal_energy_t, float) dev_matched_ecal_energy;
    DEVICE_OUTPUT(dev_matched_ecal_digits_size_t, unsigned) dev_matched_ecal_digits_size;
    DEVICE_OUTPUT(dev_matched_ecal_digits_t, std::array<unsigned, 6>) dev_matched_ecal_digits;
    DEVICE_OUTPUT(dev_track_inEcalAcc_t, bool) dev_track_inEcalAcc;
    DEVICE_OUTPUT(dev_track_Eop_t, float) dev_track_Eop;
    DEVICE_OUTPUT(dev_track_Eop3x3_t, float) dev_track_Eop3x3;
    DEVICE_OUTPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    DEVICE_OUTPUT(dev_delta_barycenter_x_t, float) dev_delta_barycenter_x;
    DEVICE_OUTPUT(dev_delta_barycenter_y_t, float) dev_delta_barycenter_y;
    DEVICE_OUTPUT(dev_delta_barycenter_t, float) dev_delta_barycenter;
    DEVICE_OUTPUT(dev_dispersion_x_t, float) dev_dispersion_x;
    DEVICE_OUTPUT(dev_dispersion_y_t, float) dev_dispersion_y;
    DEVICE_OUTPUT(dev_region_t, int) dev_region;
    DEVICE_OUTPUT(dev_dispersion_xy_t, float) dev_dispersion_xy;
    DEVICE_OUTPUT(dev_track_local_max_t, bool) dev_track_local_max;
    DEVICE_OUTPUT(dev_ecal_digits_isTrackMatched_t, bool) dev_ecal_digits_isTrackMatched;
  };

  struct track_digit_selective_matching_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      Allen::Context const&) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  };

  __global__ void track_digit_selective_matching(Parameters parameters, const char* raw_ecal_geometry);

  template<typename MultiEventTracks>
  __device__ void track_digit_selective_matching_implementation(
    Parameters parameters,
    const MultiEventTracks* dev_long_tracks_view,
    const char* raw_ecal_geometry);
} // namespace track_digit_selective_matching
