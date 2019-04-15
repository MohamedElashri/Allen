#include "LFCollectCandidates.cuh"
#include "LFCollectCandidatesImpl.cuh"

__global__ void lf_collect_candidates(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
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

  UT::Consolidated::Tracks ut_tracks {(uint*) dev_atomics_ut,
                                      (uint*) dev_ut_track_hit_number,
                                      (float*) dev_ut_qop,
                                      (uint*) dev_ut_track_velo_indices,
                                      event_number,
                                      number_of_events};

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits(dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res);

  // if (threadIdx.x == 0) {
  //   printf("Number of hits in event: %i\n", scifi_hit_count.event_number_of_hits());
  // }
  
  for (int i = threadIdx.x; i < ut_event_number_of_tracks; i += blockDim.x) {
    const float ut_qop = ut_tracks.qop[i];
    lf_collect_candidates_impl(
      scifi_hits,
      dev_initial_windows + ut_event_tracks_offset + i,
      ut_qop,
      ut_total_number_of_tracks,
      dev_scifi_lf_number_of_candidates + LookingForward::number_of_x_layers * (ut_event_tracks_offset + i),
      dev_scifi_lf_candidates + (ut_event_tracks_offset + i)
        * LookingForward::number_of_x_layers * LookingForward::maximum_number_of_candidates,
      scifi_hit_count.event_offset(),
      scifi_hit_count.event_number_of_hits());
  }
}
