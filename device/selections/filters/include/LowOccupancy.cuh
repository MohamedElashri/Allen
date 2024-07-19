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

    PROPERTY(minTracks_t, "minTracks", "minimum number of Velo tracks in the event", unsigned int) minTracks;
    PROPERTY(maxTracks_t, "maxTracks", "maximum number of Velo tracks in the event", unsigned int) maxTracks;
    PROPERTY(min_ecal_clusters_t, "min_ecal_clusters", "Maximum number of ECAL clusters", unsigned) min_ecal_clusters;
    PROPERTY(max_ecal_clusters_t, "max_ecal_clusters", "Maximum number of ECAL clusters", unsigned) max_ecal_clusters;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned);
  };

  __global__ void low_occupancy(Parameters, const unsigned, const unsigned);
  struct low_occupancy_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 256};
    Property<minTracks_t> m_minTracks {this, 0};
    Property<maxTracks_t> m_maxTracks {this, UINT_MAX};
    Property<max_ecal_clusters_t> m_max_ecal_clusters {this, UINT_MAX};
    Property<min_ecal_clusters_t> m_min_ecal_clusters {this, 0};
  }; // low_occupancy_t

} // namespace low_occupancy
