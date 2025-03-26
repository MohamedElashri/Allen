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
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "AlgorithmTypes.cuh"

namespace ut_copy_track_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_ut_track_hits_t, unsigned) host_number_of_ut_tracks;
    DEVICE_INPUT(dev_ut_track_selected_offset_t, unsigned) dev_ut_track_selected_offset;
    DEVICE_INPUT(dev_ut_track_hits_offset_t, unsigned) dev_ut_track_hits_offset;
    DEVICE_INPUT(dev_ut_track_hits_t, UT::TrackHits) dev_ut_track_hits;
    DEVICE_OUTPUT(dev_offsets_ut_track_hit_number_t, unsigned) dev_offsets_ut_track_hit_number;
    HOST_OUTPUT(host_accumulated_number_of_hits_in_ut_tracks_t, unsigned) host_accumulated_number_of_hits_in_ut_tracks;
  };

  __global__ void ut_copy_track_hit_number(Parameters);

  struct ut_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {512, 1, 1}, "block dimensions"};
  };
} // namespace ut_copy_track_hit_number