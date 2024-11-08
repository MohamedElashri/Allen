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

namespace pv_activity_filter {
  struct Parameters {
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_number_of_multi_final_vertices_t, unsigned) dev_number_of_multi_final_vertices;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(minPVs_t, "minPVs", "min number of PVs to accept an event", unsigned) minPVs;
    PROPERTY(maxPVs_t, "maxPVs", "max number of PVs to accept an event", unsigned) maxPVs;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
  };

  __global__ void pv_activity_filter(Parameters, const unsigned);
  struct pv_activity_filter_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<minPVs_t> m_minPVs {this, 1};
    Property<maxPVs_t> m_maxPVs {this, UINT_MAX};
  }; // pv_activity_filter_t

} // namespace pv_activity_filter
