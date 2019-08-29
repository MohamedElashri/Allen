#include "MomentumForwardStudies.h"
#include "LookingForwardStudies.h"
#include "TrackChecker.h"
#include "PrepareTracks.h"

/**
 * @brief Specialization for any Velo reconstruction algorithm invoking
 *        consolidate_ut_tracks_t as last step.
 */
template<>
void SequenceVisitor::check<consolidate_ut_tracks_t>(
  HostBuffers& host_buffers,
  const Constants& constants,
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

  std::vector<std::vector<float>> p_events;
  auto& checker = checker_invoker.checker<TrackCheckerVeloUT>("Velo+UT tracks:", "PrCheckerPlots.root");
  host_buffers.scifi_ids_ut_tracks = checker.accumulate<TrackCheckerVeloUT>(mc_events, tracks, p_events);

  // Run MomentumForward on x86
  const auto scifi_trackhits = looking_forward_studies(
    host_buffers.host_scifi_hits.data(),
    host_buffers.host_scifi_hit_count.data(),
    constants.host_scifi_geometry.data(),
    constants.host_inv_clus_res,
    host_buffers.host_atomics_velo,
    host_buffers.host_velo_track_hit_number,
    host_buffers.host_velo_states.data(),
    host_buffers.host_atomics_ut,
    host_buffers.host_ut_track_hit_number,
    host_buffers.host_ut_qop,
    host_buffers.host_ut_x,
    host_buffers.host_ut_tx,
    host_buffers.host_ut_z,
    host_buffers.host_ut_track_velo_indices,
    host_buffers.scifi_ids_ut_tracks,
    p_events,
    host_buffers.host_number_of_selected_events[0],
    host_buffers.host_scifi_tracks,
    host_buffers.host_atomics_scifi);

  if (scifi_trackhits.size() > 0) {
    // Convert tracks to format expected by checker
    const uint total_number_of_hits =
      host_buffers
        .host_scifi_hit_count[host_buffers.host_number_of_selected_events[0] * SciFi::Constants::n_mat_groups_and_mats];

    SciFi::Hits scifi_hits {(uint*) host_buffers.host_scifi_hits.data(),
                            total_number_of_hits,
                            reinterpret_cast<const SciFi::SciFiGeometry*>(&constants.host_scifi_geometry),
                            reinterpret_cast<const float*>(constants.host_inv_clus_res.data())};

    const auto scifi_tracks = prepareSciFiTracks(
      host_buffers.host_atomics_velo,
      host_buffers.host_velo_track_hit_number,
      host_buffers.host_velo_track_hits,
      host_buffers.host_kalmanvelo_states,
      host_buffers.host_atomics_ut,
      host_buffers.host_ut_track_hit_number,
      host_buffers.host_ut_track_hits,
      host_buffers.host_ut_track_velo_indices,
      host_buffers.host_ut_qop,
      scifi_trackhits,
      scifi_hits,
      host_buffers.host_scifi_hit_count.data(),
      host_buffers.host_number_of_selected_events[0]);

    std::vector<std::vector<float>> p_events_scifi;
    auto& forward_checker =
      checker_invoker.checker<TrackCheckerForward>("Checking x86 MomentumForward tracks", "PrCheckerPlots.root");
    forward_checker.accumulate<TrackCheckerForward>(mc_events, scifi_tracks, p_events_scifi);
  }
}
