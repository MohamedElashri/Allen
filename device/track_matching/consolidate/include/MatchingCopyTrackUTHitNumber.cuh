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
#include "SciFiEventModel.cuh"
#include "TrackMatchingConstants.cuh"
#include "AlgorithmTypes.cuh"

namespace matching_copy_track_ut_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_matched_tracks_t, unsigned) host_number_of_reconstructed_matched_tracks;
    DEVICE_INPUT(dev_matched_tracks_t, SciFi::MatchedTrack) dev_matched_tracks;
    DEVICE_INPUT(dev_offsets_matched_tracks_t, unsigned) dev_offsets_matched_tracks;
    DEVICE_OUTPUT(dev_offsets_matched_ut_hit_number_t, unsigned) dev_offsets_matched_ut_hit_number;
    HOST_OUTPUT(host_total_sum_holder_t, unsigned)
    host_total_sum_holder;
  };
  __global__ void matching_copy_track_ut_hit_number(Parameters);

  struct matching_copy_track_ut_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {512, 1, 1}, "block dimensions"};
  };
} // namespace matching_copy_track_ut_hit_number
