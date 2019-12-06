#include "TrackChecker.h"
#include "PrepareTracks.h"

/**
 * @brief Specialization for any Velo reconstruction algorithm invoking
 *        consolidate_ut_tracks_t as last step.
 */
template<>
void SequenceVisitor::check<ut_consolidate_tracks_t>(
  HostBuffers& host_buffers,
  const Constants&,
  const CheckerInvoker& checker_invoker,
  MCEvents const& mc_events) const
{
  const auto tracks = prepareUTTracks(
    host_buffers.host_atomics_velo,
    host_buffers.host_velo_track_hit_number,
    host_buffers.host_velo_track_hits,
    host_buffers.host_kalmanvelo_states,
    host_buffers.host_atomics_ut,
    host_buffers.host_ut_track_hit_number,
    host_buffers.host_ut_track_hits,
    host_buffers.host_ut_track_velo_indices,
    host_buffers.host_ut_qop,
    host_buffers.host_number_of_selected_events[0]);

  auto& checker = checker_invoker.checker<TrackCheckerVeloUT>("Velo+UT tracks:", "PrCheckerPlots.root");
  checker.accumulate<TrackCheckerVeloUT>(mc_events, tracks);
}
