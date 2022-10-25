/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "VeloConsolidated.cuh"

namespace brem_recovery {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    // Velo tracks
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    // Calo digits
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    // Output
    DEVICE_OUTPUT(dev_brem_E_t, float) dev_brem_E;
    DEVICE_OUTPUT(dev_brem_ET_t, float) dev_brem_ET;
    DEVICE_OUTPUT(dev_brem_inECALacc_t, bool) dev_brem_inECALacc;
    DEVICE_OUTPUT(dev_brem_ecal_digits_size_t, unsigned) dev_brem_ecal_digits_size;
    DEVICE_OUTPUT(dev_brem_ecal_digits_t, std::array<unsigned, 4>) dev_brem_ecal_digits;
    // Properties
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  struct brem_recovery_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      Allen::Context const&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

  __global__ void brem_recovery(Parameters parameters, const char* raw_ecal_geometry);
} // namespace brem_recovery