/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "VeloConsolidateTracks.cuh"
#include "TrackChecker.h"
#include "PrepareTracks.h"

/**
 * @brief Specialization for any Velo reconstruction algorithm invoking
 *        consolidate_tracks_t as last step.
 */
template<>
struct SequenceVisitor<velo_consolidate_tracks::velo_consolidate_tracks_t> {
  static void check(
    HostBuffers& host_buffers,
    const Constants&,
    const CheckerInvoker& checker_invoker,
    MCEvents const& mc_events) {
    const auto tracks = prepareVeloTracks(
      host_buffers.host_atomics_velo,
      host_buffers.host_velo_track_hit_number,
      host_buffers.host_velo_track_hits,
      host_buffers.host_number_of_events,
      host_buffers.host_number_of_selected_events,
      host_buffers.host_event_list);

    auto& checker = checker_invoker.checker<TrackCheckerVelo>("\nVelo tracks:", "PrCheckerPlots.root");
    checker.accumulate<TrackCheckerVelo>(mc_events, tracks);
  }
};
