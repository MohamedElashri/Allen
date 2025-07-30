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
#include "States.cuh"

namespace check_localized_beamline_ip {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;

    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;
  };

  __global__ void check_localized_beamline_ip(Parameters, const float, const float, const float, const float);
  struct check_localized_beamline_ip_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<float> m_min_state_z {this,
                                          "min_state_z",
                                          -99999.,
                                          "min z coordinate of region in which to count velo tracks"};
    Allen::Property<float> m_max_state_z {this,
                                          "max_state_z",
                                          99999.,
                                          "max z coordinate of region in which to count velo tracks"};
    Allen::Property<float> m_max_state_rho_sq {
      this,
      "max_state_rho_sq",
      99999.,
      "max square of cylindrical radius of beamline state in which to count velo tracks"};
    Allen::Property<float> m_min_local_nTracks {this,
                                                "min_local_nTracks",
                                                10.,
                                                "min number of tracks in the designated region"};
  };

} // namespace check_localized_beamline_ip
