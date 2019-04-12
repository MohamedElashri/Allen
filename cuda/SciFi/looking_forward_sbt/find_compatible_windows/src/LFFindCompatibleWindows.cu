#include "LFFindCompatibleWindows.cuh"
#include "LFFindCompatibleWindowsImpl.cuh"
#include "TrackUtils.cuh"

__global__ void lf_find_compatible_windows(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const MiniState* dev_ut_states,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  const uint* dev_scifi_lf_number_of_candidates,
  const short* dev_scifi_lf_candidates,
  short* dev_scifi_lf_compatible_windows,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;
  const auto ut_total_number_of_tracks = dev_atomics_ut[2 * number_of_events];

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);

  const auto total_number_of_candidates = dev_scifi_lf_number_of_candidates[ut_total_number_of_tracks * LookingForward::number_of_x_layers];

  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const auto ut_state = dev_ut_states[ut_event_tracks_offset + i];
    const float z_ref_track = SciFi::Tracking::zReference;
    const float x_at_ref = xFromVelo(z_ref_track, ut_state);
    const float z_mag = LookingForward::zMagnetParams_0 +
                   LookingForward::zMagnetParams_2 * ut_state.tx * ut_state.tx +
                   LookingForward::zMagnetParams_3 * ut_state.ty * ut_state.ty;

    for (uint8_t j = threadIdx.y; j < 8; j += blockDim.y) {
      lf_find_compatible_windows_impl(
        scifi_hits,
        j,
        dev_scifi_lf_number_of_candidates + (ut_event_tracks_offset + i) * LookingForward::number_of_x_layers,
        dev_scifi_lf_candidates +
          (ut_event_tracks_offset + i) * LookingForward::number_of_x_layers * LookingForward::maximum_number_of_candidates,
        dev_looking_forward_constants,
        ut_state.tx,
        x_at_ref,
        z_mag,
        ut_total_number_of_tracks,
        dev_scifi_lf_compatible_windows,
        total_number_of_candidates,
        ut_event_tracks_offset);
    }
  }
}
