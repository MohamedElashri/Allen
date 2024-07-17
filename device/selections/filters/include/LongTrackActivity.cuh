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
#include "ParticleTypes.cuh"

namespace long_track_activity_filter {
  struct Parameters {
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;

    PROPERTY(min_long_tracks_t, "min_long_tracks", "minimum number of long tracks in the event", unsigned int)
    min_long_tracks;
    PROPERTY(max_long_tracks_t, "max_long_tracks", "maximum number of long tracks in the event", unsigned int)
    max_long_tracks;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
  };

  __global__ void long_track_activity_filter(Parameters, const unsigned);
  struct long_track_activity_filter_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<min_long_tracks_t> m_min_long_tracks {this, 1};
    Property<max_long_tracks_t> m_max_long_tracks {this, UINT_MAX};
  }; // long_track_activity_filter_t

} // namespace long_track_activity_filter
