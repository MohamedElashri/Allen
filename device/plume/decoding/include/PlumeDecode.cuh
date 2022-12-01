/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

#pragma once

#include "PlumeRawEvent.cuh"
#include "Plume.cuh"
#include "AlgorithmTypes.cuh"

namespace plume_decode {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_raw_bank_version_t, int) host_raw_bank_version;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_plume_raw_input_t, char) dev_plume_raw_input;
    DEVICE_INPUT(dev_plume_raw_input_offsets_t, unsigned) dev_plume_raw_input_offsets;
    DEVICE_INPUT(dev_plume_raw_input_sizes_t, unsigned) dev_plume_raw_input_sizes;
    DEVICE_INPUT(dev_plume_raw_input_types_t, unsigned) dev_plume_raw_input_types;
    DEVICE_OUTPUT(dev_plume_t, Plume_) dev_plume;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  struct plume_decode_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&)
      const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };

} // namespace plume_decode
