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

#include "DeviceAlgorithm.cuh"
#include "CandidateTable.cuh"

namespace make_rb_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_total_hits_bank_size_t, unsigned) host_total_hits_bank_size;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_hits_container_t, unsigned) dev_hits_container;
    DEVICE_INPUT_OPTIONAL(dev_offsets_forward_tracks_t, unsigned) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_sel_track_tables_t, Selections::CandidateTable) dev_sel_track_tables;
    DEVICE_INPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    DEVICE_INPUT(dev_hits_offsets_t, unsigned) dev_hits_offsets;
    DEVICE_INPUT(dev_sel_hits_offsets_t, unsigned) dev_sel_hits_offsets;
    DEVICE_OUTPUT(dev_rb_hits_t, unsigned) dev_rb_hits;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void make_bank(Parameters);

  struct make_rb_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

} // namespace make_rb_hits