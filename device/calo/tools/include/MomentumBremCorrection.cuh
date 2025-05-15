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

#include "ParKalmanFittedTrack.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "AllenMonitoring.h"

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
    DEVICE_INPUT(dev_track_Eop_t, float) dev_track_Eop;
    // Outputs
    DEVICE_OUTPUT(dev_brem_corrected_p_t, float) dev_brem_corrected_p;
    DEVICE_OUTPUT(dev_brem_corrected_pt_t, float) dev_brem_corrected_pt;
  };

  __global__ void momentum_brem_correction(
    Parameters,
    const float,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType,
    Allen::Monitoring::Histogram<>::DeviceType);

  struct momentum_brem_correction_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> min_bremeop {this, "min_bremeop", 0.05f, "Minimum E/p for hist_Eop_hasBrem"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
    Allen::Monitoring::Histogram<> m_hist_Eop {this, "EoverP", "E (Ecal) / P (track)", {100u, 1e-5f, 2.f}};
    Allen::Monitoring::Histogram<> m_hist_Eop_hasBrem {this,
                                                       "EoverP_hasbrem",
                                                       "E (Ecal) / P (track) (with HasBrem)",
                                                       {100u, 1e-5f, 2.f}};
    Allen::Monitoring::Histogram<> m_hist_brem {this,
                                                "BremEoverP",
                                                "BremE/ ( BremE + P (track) )",
                                                {100u, 1e-5f, 1.01f}};
  };

} // namespace momentum_brem_correction
