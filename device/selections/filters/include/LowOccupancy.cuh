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
#include "VeloConsolidated.cuh"

namespace low_occupancy {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;

    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    HOST_INPUT(host_ecal_number_of_clusters_t, unsigned) host_ecal_number_of_clusters;
    DEVICE_INPUT(dev_ecal_cluster_offsets_t, unsigned) dev_ecal_cluster_offsets;
    DEVICE_OUTPUT(dev_number_of_selected_events_t, unsigned) dev_number_of_selected_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list_output;
  };

  __global__ void low_occupancy(
    Parameters,
    const unsigned,
    const unsigned,
    const unsigned,
    const unsigned,
    const unsigned,
    const unsigned);
  struct low_occupancy_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 256, "block dimension x"};
    Allen::Property<unsigned> m_minTracks {this, "minTracks", 0, "minimum number of Velo tracks in the event"};
    Allen::Property<unsigned> m_maxTracks {this, "maxTracks", UINT_MAX, "maximum number of Velo tracks in the event"};
    Allen::Property<unsigned> m_max_ecal_clusters {this,
                                                   "max_ecal_clusters",
                                                   UINT_MAX,
                                                   "Maximum number of ECAL clusters"};
    Allen::Property<unsigned> m_min_ecal_clusters {this, "min_ecal_clusters", 0, "Maximum number of ECAL clusters"};
  }; // low_occupancy_t

} // namespace low_occupancy
