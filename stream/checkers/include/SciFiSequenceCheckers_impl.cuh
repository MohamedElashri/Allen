/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PrepareTracks.h"
#include "ConsolidateSciFi.cuh"

/**
 * @brief Specialization when invoking scifi_pr_forward_t as last step.
 */
template<>
struct SequenceVisitor<scifi_consolidate_tracks::scifi_consolidate_tracks_t> {
  static void check(
    HostBuffers& host_buffers,
    const Constants& constants,
    const CheckerInvoker& checker_invoker,
    MCEvents const& mc_events)
  {
    const auto tracks = prepareSciFiTracks(
      host_buffers.host_atomics_velo,
      host_buffers.host_velo_track_hit_number,
      host_buffers.host_velo_track_hits,
      host_buffers.host_kalmanvelo_states,
      host_buffers.host_atomics_ut,
      host_buffers.host_ut_track_hit_number,
      host_buffers.host_ut_track_hits,
      host_buffers.host_ut_track_velo_indices,
      host_buffers.host_ut_qop,
      host_buffers.host_atomics_scifi,
      host_buffers.host_scifi_track_hit_number,
      host_buffers.host_scifi_track_hits,
      host_buffers.host_scifi_track_ut_indices,
      host_buffers.host_scifi_qop,
      host_buffers.host_scifi_states,
      constants.host_scifi_geometry.data(),
      constants.host_inv_clus_res,
      host_buffers.host_muon_catboost_output,
      host_buffers.host_is_muon,
      host_buffers.host_number_of_selected_events[0]);

    auto& checker = checker_invoker.checker<TrackCheckerForward>("Forward tracks:", "PrCheckerPlots.root");
    checker.accumulate<TrackCheckerForward>(mc_events, tracks);
  }
};
