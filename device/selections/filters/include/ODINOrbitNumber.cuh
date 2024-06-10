/**************************************************************************** \
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ODINBank.cuh"

namespace odin_orbitnumber {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(odin_orbit_modulo_t, "odin_orbit_modulo", "Modulo for ODIN orbit number test", unsigned) odin_orbit_modulo;
    PROPERTY(odin_orbit_remainder_t, "odin_orbit_remainder", "Remainder for ODIN orbit number test", unsigned)
    odin_orbit_remainder;

    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
  };

  struct odin_orbitnumber_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<odin_orbit_modulo_t> m_odin_orbit_modulo {this, 30u};
    Property<odin_orbit_remainder_t> m_odin_orbit_remainder {this, 1u};
  }; // odin_orbitnumber_t
} // namespace odin_orbitnumber
