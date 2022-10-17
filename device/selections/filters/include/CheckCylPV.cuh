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

    PROPERTY(min_vtx_z_t, "min_vtx_z", "min z coordinate to accept a reconstructed primary vertex", float) min_vtx_z;
    PROPERTY(max_vtz_z_t, "max_vtz_z", "max z coordinate to accept a reconstructed primary vertex", float) max_vtz_z;
    PROPERTY(
      max_vtx_rho_sq_t,
      "max_vtx_rho_sq",
      "max square of cylindrical radius coordinate to accept a reconstructed primary vertex",
      float)
    max_vtx_rho_sq;
    PROPERTY(
      min_vtx_nTracks_t,
      "min_vtx_nTracks",
      "min number of tracks in the PV to accept a reconstructed primary vertex",
      float)
    min_vtx_nTracks;
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
    Property<min_vtx_z_t> m_min_vtx_z {this, -99999.};
    Property<max_vtz_z_t> m_max_vtz_z {this, 99999.};
    Property<max_vtx_rho_sq_t> m_max_vtx_rho_sq {this, 99999.};
    Property<min_vtx_nTracks_t> m_min_vtx_nTracks {this, 10.};
  }; // check_cyl_pvs_t

} // namespace check_cyl_pvs
