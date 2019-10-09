#include "LFCollectCandidates.cuh"
#include "LFCollectCandidatesImpl.cuh"

__global__ void lf_collect_candidates(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  uint* dev_scifi_lf_number_of_candidates,
  short* dev_scifi_lf_candidates)
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

  for (uint i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    lf_collect_candidates_p_impl(
      scifi_hits,
      dev_initial_windows + ut_event_tracks_offset + i,
      ut_total_number_of_tracks,
      dev_scifi_lf_number_of_candidates + LookingForward::number_of_x_layers * (ut_event_tracks_offset + i),
      dev_scifi_lf_candidates + (ut_event_tracks_offset + i) * LookingForward::number_of_x_layers *
                                  LookingForward::maximum_number_of_candidates,
      scifi_hit_count.event_offset());
  }
}
