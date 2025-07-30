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
#include "VeloEventModel.cuh"
#include "AlgorithmTypes.cuh"

namespace velo_copy_track_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_velo_tracks_at_least_four_hits_t, unsigned)
    host_number_of_velo_tracks_at_least_four_hits;
    HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, unsigned) host_number_of_three_hit_tracks_filtered;
    HOST_OUTPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_OUTPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    HOST_OUTPUT(host_accumulated_number_of_hits_in_velo_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_velo_tracks;
    DEVICE_OUTPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
  };

  __global__ void velo_copy_track_hit_number(Parameters);

  struct velo_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {512, 1, 1}, "block dimensions"};
  };
} // namespace velo_copy_track_hit_number