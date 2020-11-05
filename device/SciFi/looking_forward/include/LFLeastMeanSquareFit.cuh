/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTConsolidated.cuh"

namespace lf_least_mean_square_fit {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_ut_t, unsigned) dev_atomics_ut;
    DEVICE_OUTPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_atomics_scifi_t, unsigned) dev_atomics_scifi;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_x_filter_t, float) dev_scifi_lf_parametrization_x_filter;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void lf_least_mean_square_fit(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  struct lf_least_mean_square_fit_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&, const HostBuffers&)
      const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace lf_least_mean_square_fit
