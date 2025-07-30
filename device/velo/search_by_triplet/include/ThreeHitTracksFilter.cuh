/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "VeloEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "States.cuh"

namespace velo_three_hit_tracks_filter {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_three_hit_tracks_input_t, Velo::TrackletHits) dev_three_hit_tracks_input;
    DEVICE_INPUT(dev_atomics_velo_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT(dev_hit_used_t, uint8_t) dev_hit_used;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_OUTPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered;
    HOST_OUTPUT(host_number_of_three_hit_tracks_filtered_t, unsigned) host_number_of_three_hit_tracks_filtered;
  };

  __global__ void velo_three_hit_tracks_filter(Parameters, const float max_chi2);

  struct velo_three_hit_tracks_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_chi2 {this, "max_chi2", 20.0f, "chi2"};
    Allen::Property<unsigned> m_max_weak {this, "max_weak_tracks", 500u, "max weak tracks"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace velo_three_hit_tracks_filter