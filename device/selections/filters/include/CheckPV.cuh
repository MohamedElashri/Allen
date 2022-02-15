/************************************************************************ \
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
\*************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "PV_Definitions.cuh"

namespace check_pvs {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list_output;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;
    DEVICE_OUTPUT(dev_event_decisions_t, unsigned) dev_event_decisions;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(minZ_t, "minZ", "min z coordinate for accepted reconstructed primary vertex", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "max z coordinate for accepted reconstructed primary vertex", float) maxZ;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void check_pvs(Parameters);
  struct check_pvs_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      const Allen::Context&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<minZ_t> m_minZ {this, -99999.};
    Property<maxZ_t> m_maxZ {this, 99999.};
  }; // check_pvs_t

} // namespace check_pvs
