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
    DEVICE_INPUT(dev_used_scifi_hits_t, unsigned) dev_used_scifi_hits; // bitset
    HOST_OUTPUT(host_number_of_scifi_hits_t, unsigned) host_number_of_scifi_hits;
    DEVICE_OUTPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_OUTPUT(dev_scifi_hits_t, char) dev_scifi_hits;
  };

  struct create_reduced_scifi_hit_container_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 256, "block dimension X"};
  };
} // namespace create_reduced_scifi_hit_container
