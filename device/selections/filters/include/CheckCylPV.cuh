/************************************************************************ \
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\*************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "PV_Definitions.cuh"

namespace check_cyl_pvs {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(minZ_t, "minZ", "min z coordinate to accept a reconstructed primary vertex", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "max z coordinate to accept a reconstructed primary vertex", float) maxZ;
    PROPERTY(
      max_rho_sq_t,
      "max_rho_sq",
      "max square of cylindrical radius coordinate to accept a reconstructed primary vertex",
      float)
    max_rho_sq;
    PROPERTY(
      min_nTracks_t,
      "min_nTracks",
      "min number of tracks in the PV to accept a reconstructed primary vertex",
      float)
    min_nTracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void check_cyl_pvs(Parameters);
  struct check_cyl_pvs_t : public DeviceAlgorithm, Parameters {

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
    Property<max_rho_sq_t> m_max_rho_sq {this, 99999.};
    Property<min_nTracks_t> m_min_nTracks {this, 10.};
  }; // check_cyl_pvs_t

} // namespace check_cyl_pvs
