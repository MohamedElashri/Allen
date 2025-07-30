/************************************************************************ \
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
  };

  __global__ void check_cyl_pvs(Parameters, const float, const float, const float, const float);
  struct check_cyl_pvs_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<float> m_min_vtx_z {this,
                                        "min_vtx_z",
                                        -99999.,
                                        "min z coordinate to accept a reconstructed primary vertex"};
    Allen::Property<float> m_max_vtz_z {this,
                                        "max_vtz_z",
                                        99999.,
                                        "max z coordinate to accept a reconstructed primary vertex"};
    Allen::Property<float> m_max_vtx_rho_sq {
      this,
      "max_vtx_rho_sq",
      99999.,
      "max square of cylindrical radius coordinate to accept a reconstructed primary vertex"};
    Allen::Property<float> m_min_vtx_nTracks {
      this,
      "min_vtx_nTracks",
      10.,
      "min number of tracks in the PV to accept a reconstructed primary vertex"};
  }; // check_cyl_pvs_t

} // namespace check_cyl_pvs
