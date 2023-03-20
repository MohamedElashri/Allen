/************************************************************************ \
 * (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
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

    PROPERTY(min_state_z_t, "min_state_z", "min z coordinate of region in which to count velo tracks", float)
    min_state_z;
    PROPERTY(max_state_z_t, "max_state_z", "max z coordinate of region in which to count velo tracks", float)
    max_state_z;
    PROPERTY(
      max_state_rho_sq_t,
      "max_state_rho_sq",
      "max square of cylindrical radius of beamline state in which to count velo tracks",
      float)
    max_state_rho_sq;
    PROPERTY(min_local_nTracks_t, "min_local_nTracks", "min number of tracks in the designated region", float)
    min_local_nTracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
  };

  __global__ void check_localized_beamline_ip(Parameters);
  struct check_localized_beamline_ip_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<min_state_z_t> m_min_state_z {this, -99999.};
    Property<max_state_z_t> m_max_state_z {this, 99999.};
    Property<max_state_rho_sq_t> m_max_state_rho_sq {this, 99999.};
    Property<min_local_nTracks_t> m_min_local_nTracks {this, 10.};
  }; // check_localized_beamline_ip_t

} // namespace check_localized_beamline_ip
