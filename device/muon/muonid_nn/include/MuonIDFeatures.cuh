/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "MuonSegmentFit.cuh"
#include "NNPropagation.cuh"

namespace muonid_features {

  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_chi2_muon_t, float) dev_chi2_muon;
    DEVICE_INPUT(dev_chi2uncorr_muon_t, float) dev_chi2uncorr_muon;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_OUTPUT(dev_muonid_features_t, float) dev_muonid_features;
    PROPERTY(block_dim_t, "block_dim", "block dimension", DeviceDimensions) block_dim;
  };

  __global__ void muonid_features(Parameters, const float* min_rescales, const float* max_rescales);

  struct muonid_features_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

} // namespace muonid_features
