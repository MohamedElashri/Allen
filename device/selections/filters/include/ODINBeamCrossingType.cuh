/************************************************************************ \
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\*************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ODINBank.cuh"

namespace odin_beamcrossingtype {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(beam_crossing_type_t, "beam_crossing_type", "ODIN beam crossing type [0-3]", unsigned) beam_crossing_type;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
    PROPERTY(invert_t, "invert", "invert on", bool) invert;
  };

  struct odin_beamcrossingtype_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<beam_crossing_type_t> m_beam_crossing_type {this, 0};
    Property<invert_t> m_invert {this, false};
  }; // odin_beamcrossingtype_t

} // namespace odin_beamcrossingtype
