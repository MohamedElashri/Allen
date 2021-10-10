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

namespace calc_selrep_size {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_rb_objtyp_offsets_t, unsigned) dev_rb_objtyp_offsets;
    DEVICE_INPUT(dev_rb_hits_offsets_t, unsigned) dev_rb_hits_offsets;
    DEVICE_INPUT(dev_rb_substr_offsets_t, unsigned) dev_rb_substr_offsets;
    DEVICE_INPUT(dev_rb_stdinfo_offsets_t, unsigned) dev_rb_stdinfo_offsets;
    DEVICE_INPUT(dev_rb_objtyp_t, unsigned) dev_rb_objtyp;
    DEVICE_OUTPUT(dev_selrep_sizes_t, unsigned) dev_selrep_sizes;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void calc_size(Parameters, const unsigned number_of_events);

  struct calc_selrep_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace calc_selrep_size
