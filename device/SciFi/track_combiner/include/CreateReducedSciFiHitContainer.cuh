/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "UTConsolidated.cuh"

namespace create_reduced_scifi_hit_container {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hit_offsets_input_t, unsigned) dev_scifi_hit_offsets_input;
    DEVICE_INPUT(dev_scifi_hits_input_t, char) dev_scifi_hits_input;
    DEVICE_INPUT(dev_used_scifi_hits_offsets_t, unsigned) dev_used_scifi_hits_offsets;
    HOST_INPUT(host_used_scifi_hits_offsets_t, unsigned) host_used_scifi_hits_offsets;
    HOST_OUTPUT(host_number_of_scifi_hits_t, unsigned) host_number_of_scifi_hits;
    DEVICE_OUTPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned);
  };

  struct create_reduced_scifi_hit_container_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
  };
} // namespace create_reduced_scifi_hit_container
