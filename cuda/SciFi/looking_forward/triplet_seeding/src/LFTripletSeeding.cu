#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "LookingForwardTools.cuh"

__global__ void lf_triplet_seeding(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const float* dev_ut_qop,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  const LookingForward::Constants* dev_looking_forward_constants,
  const MiniState* dev_ut_states,
  SciFi::CombinedValue* dev_scifi_lf_triplet_best,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi)
{
  __shared__ float shared_partial_chi2[LookingForward::tile_size * LookingForward::tile_size];

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
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  constexpr int number_of_seeds = 4;
  uint triplet_seeding_layers[number_of_seeds][3] {
    {0, 1, 2},
    {1, 2, 3},
    {2, 3, 4},
    {3, 4, 5}
  };

  for (uint i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto qop = dev_ut_qop[current_ut_track_index];
    const int* initial_windows = dev_initial_windows + current_ut_track_index;

    for (uint triplet_seed = 0; triplet_seed < number_of_seeds; ++triplet_seed) {
      const auto layer_0 = triplet_seeding_layers[triplet_seed][0];
      const auto layer_1 = triplet_seeding_layers[triplet_seed][1];
      const auto layer_2 = triplet_seeding_layers[triplet_seed][2];

      int l0_start = initial_windows[(layer_0 * 8) * ut_total_number_of_tracks];
      int l0_extrapolated = initial_windows[(layer_0 * 8 + 4) * ut_total_number_of_tracks];
      int l0_size = initial_windows[(layer_0 * 8 + 1) * ut_total_number_of_tracks];

      int l1_start = initial_windows[(layer_1 * 8) * ut_total_number_of_tracks];
      int l1_extrapolated = initial_windows[(layer_1 * 8 + 4) * ut_total_number_of_tracks];
      int l1_size = initial_windows[(layer_1 * 8 + 1) * ut_total_number_of_tracks];

      int l2_start = initial_windows[(layer_2 * 8) * ut_total_number_of_tracks];
      int l2_extrapolated = initial_windows[(layer_2 * 8 + 4) * ut_total_number_of_tracks];
      int l2_size = initial_windows[(layer_2 * 8 + 1) * ut_total_number_of_tracks];

      const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
      const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];
      const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

      lf_triplet_seeding_impl(
        scifi_hits.x0 + event_offset,
        layer_0,
        layer_1,
        layer_2,
        l0_start,
        l1_start,
        l2_start,
        l0_extrapolated,
        l1_extrapolated,
        l2_extrapolated,
        l0_size,
        l1_size,
        l2_size,
        z0,
        z1,
        z2,
        qop,
        dev_ut_states + current_ut_track_index,
        shared_partial_chi2,
        dev_scifi_tracks + current_ut_track_index * LookingForward::maximum_number_of_candidates_per_ut_track,
        dev_atomics_scifi + current_ut_track_index,
        dev_looking_forward_constants,
        i,
        number_of_seeds);
    }
  }
}
