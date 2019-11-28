#include "RateChecker.h"
#include "SelCheckerTuple.h"
#include "PrepareKalmanTracks.h"

template<>
void SequenceVisitor::check<run_hlt1_t>(
  HostBuffers& host_buffers,
  const Constants& constants,
  const CheckerInvoker& checker_invoker,
  const MCEvents& mc_events) const
{
  auto& checker = checker_invoker.checker<RateChecker>("HLT1 rates:");
  checker.accumulate(
    host_buffers.host_one_track_decisions,
    host_buffers.host_two_track_decisions,
    host_buffers.host_single_muon_decisions,
    host_buffers.host_disp_dimuon_decisions,
    host_buffers.host_high_mass_dimuon_decisions,
    host_buffers.host_dimuon_soft_decisions,

    host_buffers.host_atomics_scifi,
    host_buffers.host_sv_offsets,
    host_buffers.host_number_of_selected_events[0]);

  [[maybe_unused]] const auto tracks = prepareKalmanTracks(
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

#ifdef WITH_ROOT
  auto& ntuple =
    checker_invoker.checker<SelCheckerTuple>("Making ntuple for efficiency studies.", "SelCheckerTuple.root");
  ntuple.accumulate(
    mc_events,
    tracks,
    host_buffers.host_secondary_vertices,
    host_buffers.host_one_track_decisions,
    host_buffers.host_two_track_decisions,
    host_buffers.host_single_muon_decisions,
    host_buffers.host_disp_dimuon_decisions,
    host_buffers.host_high_mass_dimuon_decisions,
    host_buffers.host_dimuon_soft_decisions,

    host_buffers.host_atomics_scifi,
    host_buffers.host_sv_offsets,
    host_buffers.host_number_of_selected_events[0]);
#else
  // Avoid warning
  [[maybe_unused]] const auto& mc_event = mc_events.front();
#endif
}
