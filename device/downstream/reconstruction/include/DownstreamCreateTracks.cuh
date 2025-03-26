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
#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"

// Event Model
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"

#include "SingleLayerFCNN.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"
#include "BinarySearch.cuh"

#include "AllenMonitoring.h"

/**
 * @brief This is a definition file of the downstream_create_tracks algorithm.
 * implementation file is in downstream_create_tracks.cu
 */
namespace downstream_create_tracks {
  constexpr unsigned MaxNumIteration = 2;
  using DownstreamGhostKiller = Allen::MVAModels::SingleLayerFCNN<11, 32>;

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // From find hits parts
    DEVICE_INPUT(dev_findhits_num_selected_scifi_t, unsigned) dev_findhits_num_selected_scifi;
    DEVICE_INPUT(dev_findhits_output_selected_scifi_offsets_t, unsigned) dev_findhits_output_selected_scifi_offsets;
    DEVICE_INPUT(dev_findhits_output_t, Downstream::DownstreamStructs::DownstreamHits) dev_findhits_output;
    DEVICE_INPUT(dev_findhits_selected_scifi_tracks_t, Downstream::DownstreamStructs::SelectedSciFiTrack)
    dev_findhits_selected_scifi_tracks;

    // UT hits
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Output
    DEVICE_OUTPUT(dev_downstream_tracks_t, UT::DownstreamTrack) dev_downstream_tracks;
    DEVICE_OUTPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    HOST_OUTPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
  };

  __global__ void downstream_create_tracks(
    Parameters,
    const float*,
    const float,
    const DownstreamGhostKiller::DeviceType*,
    [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType);

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
    Allen::Monitoring::Counter<> m_n_overflow_downstream_create_tracks {this, "n_overflow_downstream_create_tracks"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
    Allen::Property<float> m_ghost_killer_threshold {this,
                                                     "ghost_killer_threshold",
                                                     0.5,
                                                     "the threshold of the ghost killer"};

    DownstreamGhostKiller dev_downstream_ghostkiller {"dev_downstream_ghostkiller",
                                                      "/GhostProbability/Hlt1_DownstreamGhostKiller.json"};
  };

} // namespace downstream_create_tracks
