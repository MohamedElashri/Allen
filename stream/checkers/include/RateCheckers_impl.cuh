#include "RateChecker.h"
#include "SelCheckerTuple.h"
#include "PrepareKalmanTracks.h"
#include "RunHlt1.cuh"
#include "ConfiguredLines.h"

template<>
struct SequenceVisitor<run_hlt1::run_hlt1_t> {
  static void check(
    HostBuffers& host_buffers,
    [[maybe_unused]] const Constants& constants,
    const CheckerInvoker& checker_invoker,
    [[maybe_unused]] MCEvents const& mc_events)
  {
    auto& checker = checker_invoker.checker<RateChecker>("HLT1 rates:");
    checker.accumulate<configured_lines_t>(
      host_buffers.host_sel_results,
      host_buffers.host_sel_results_atomics,
      host_buffers.host_atomics_scifi,
      host_buffers.host_sv_offsets,
      host_buffers.host_number_of_events,
      host_buffers.host_number_of_selected_events[0]);

#ifdef WITH_ROOT
    const auto tracks = prepareKalmanTracks(
      host_buffers.host_atomics_velo,
      host_buffers.host_velo_track_hit_number,
      host_buffers.host_velo_track_hits,
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
      host_buffers.host_kf_tracks,
      host_buffers.host_kalmanvelo_states,
      host_buffers.host_reconstructed_multi_pvs,
      host_buffers.host_number_of_multivertex,
      host_buffers.host_number_of_selected_events[0]);

    auto& ntuple =
      checker_invoker.checker<SelCheckerTuple>("Making ntuple for efficiency studies.", "SelCheckerTuple.root");
    ntuple.accumulate<configured_lines_t>(
      mc_events,
      tracks,
      host_buffers.host_secondary_vertices,
      host_buffers.host_sel_results,
      host_buffers.host_sel_results_atomics,
      host_buffers.host_atomics_scifi,
      host_buffers.host_sv_offsets,
      host_buffers.host_mf_sv_offsets,
      host_buffers.host_number_of_selected_events[0]);
#endif
  }
};
