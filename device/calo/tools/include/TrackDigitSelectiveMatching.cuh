/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
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
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    // Calo digits
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    // Outputs
    DEVICE_OUTPUT(dev_matched_ecal_energy_t, float) dev_matched_ecal_energy;
    DEVICE_OUTPUT(dev_matched_ecal_digits_size_t, unsigned) dev_matched_ecal_digits_size;
    DEVICE_OUTPUT(dev_matched_ecal_digits_t, std::array<unsigned, 6>) dev_matched_ecal_digits;
    DEVICE_OUTPUT(dev_track_inEcalAcc_t, bool) dev_track_inEcalAcc;
    DEVICE_OUTPUT(dev_track_Eop_t, float) dev_track_Eop;
    DEVICE_OUTPUT(dev_track_isElectron_t, bool) dev_track_isElectron;
    // Properties
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  struct track_digit_selective_matching_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      Allen::Context const&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

  __global__ void track_digit_selective_matching(Parameters parameters, const char* raw_ecal_geometry);
} // namespace track_digit_selective_matching
