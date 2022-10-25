/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "ParKalmanFittedTrack.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace momentum_brem_correction {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_track_offsets;
    // Velo tracks
    DEVICE_INPUT(dev_velo_tracks_offsets_t, unsigned) dev_velo_tracks_offsets;
    // Long tracks
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    // Calo
    DEVICE_INPUT(dev_brem_E_t, float) dev_brem_E;
    DEVICE_INPUT(dev_brem_ET_t, float) dev_brem_ET;
    // Outputs
    DEVICE_OUTPUT(dev_brem_corrected_p_t, float) dev_brem_corrected_p;
    DEVICE_OUTPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void momentum_brem_correction(Parameters);

  struct momentum_brem_correction_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

} // namespace momentum_brem_correction
