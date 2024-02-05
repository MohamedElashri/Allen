/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"

// Event Model
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamCache.cuh"
#include "DownstreamGhostKiller.cuh"

/**
 * @brief This is a definition file of the downstream_create_tracks algorithm.
 * implementation file is in downstream_create_tracks.cu
 */
namespace downstream_create_tracks {

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Find hits output table
    DEVICE_INPUT(dev_find_hits_output_table_t, char) dev_find_hits_output_table;
    DEVICE_INPUT(dev_find_hits_num_row_output_table_t, unsigned) dev_find_hits_num_row_output_table;

    // Output SciFi
    DEVICE_INPUT(dev_selected_scifi_t, unsigned) dev_selected_scifi;
    DEVICE_INPUT(dev_num_selected_scifi_t, unsigned) dev_num_selected_scifi;
    DEVICE_INPUT(dev_selected_scifi_offsets_t, unsigned) dev_selected_scifi_offsets;
    DEVICE_INPUT(dev_selected_scifi_qop_t, float) dev_selected_scifi_qop;     // for ghost killer
    DEVICE_INPUT(dev_selected_scifi_chi2Y_t, float) dev_selected_scifi_chi2Y; // for ghost killer

    // Output
    DEVICE_OUTPUT(dev_downstream_tracks_t, char) dev_downstream_tracks;
    DEVICE_OUTPUT(dev_num_downstream_tracks_t, unsigned) dev_num_downstream_tracks;

    // Block size
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(ghost_killer_threshold_t, "ghost_killer_threshold", "the threshold of the ghost killer", float)
    ghost_killer_threshold;
  };

  __global__ void downstream_create_tracks(Parameters);

  struct downstream_create_tracks_t : public DeviceAlgorithm,
                                      Parameters

  {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<ghost_killer_threshold_t> m_ghost_killer_threshold {this, 0.5};
  };

} // namespace downstream_create_tracks
