#include "LFTripletSeeding.cuh"
#include "LFTripletSeedingImpl.cuh"
#include "LookingForwardTools.cuh"
#include "Invoke.cuh"

void lf_triplet_seeding_t::invoke() {
  invoke_helper(handler);
}

__global__ void lf_triplet_seeding(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const float* dev_ut_qop,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const uint* dev_scifi_lf_number_of_candidates,
  const short* dev_scifi_lf_candidates,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::CombinedValue* dev_scifi_lf_triplet_best)
{
  __shared__ float shared_partial_chi2[LookingForward::tile_size * LookingForward::tile_size];

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  // UT consolidated tracks
  const auto ut_event_tracks_offset = dev_atomics_ut[number_of_events + event_number];
  const auto ut_event_number_of_tracks = dev_atomics_ut[number_of_events + event_number + 1] - ut_event_tracks_offset;

  // SciFi hits
  const uint total_number_of_hits = dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];
  const SciFi::HitCount scifi_hit_count {(uint32_t*) dev_scifi_hit_count, event_number};
  const SciFi::SciFiGeometry scifi_geometry {dev_scifi_geometry};
  const SciFi::Hits scifi_hits {dev_scifi_hits, total_number_of_hits, &scifi_geometry, dev_inv_clus_res};
  const auto event_offset = scifi_hit_count.event_offset();

  for (uint16_t i = blockIdx.y; i < ut_event_number_of_tracks; i += gridDim.y) {
    const auto current_ut_track_index = ut_event_tracks_offset + i;
    const auto scifi_lf_candidates = dev_scifi_lf_candidates + current_ut_track_index *
                                                                 LookingForward::number_of_x_layers *
                                                                 LookingForward::maximum_number_of_candidates;

    const auto qop = dev_ut_qop[current_ut_track_index];

    for (uint8_t triplet_seed = 0; triplet_seed < LookingForward::n_triplet_seeds; ++triplet_seed) {
      const uint8_t layer_0 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][0];
      const uint8_t layer_1 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][1];
      const uint8_t layer_2 = dev_looking_forward_constants->triplet_seeding_layers[triplet_seed][2];
      const uint8_t candidate_h0_size =
        dev_scifi_lf_number_of_candidates[current_ut_track_index * LookingForward::number_of_x_layers + layer_0];
      const uint8_t candidate_h1_size =
        dev_scifi_lf_number_of_candidates[current_ut_track_index * LookingForward::number_of_x_layers + layer_1];
      const uint8_t candidate_h2_size =
        dev_scifi_lf_number_of_candidates[current_ut_track_index * LookingForward::number_of_x_layers + layer_2];

      const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
      const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];
      const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

      lf_triplet_seeding_impl(
        scifi_hits.x0 + event_offset,
        candidate_h0_size,
        candidate_h1_size,
        candidate_h2_size,
        layer_0,
        layer_1,
        layer_2,
        dev_scifi_lf_triplet_best + (current_ut_track_index * LookingForward::n_triplet_seeds + triplet_seed) *
                                      LookingForward::maximum_number_of_candidates *
                                      LookingForward::maximum_number_of_triplets_per_h1,
        scifi_lf_candidates,
        z1 - z0,
        z2 - z0,
        qop,
        shared_partial_chi2);
    }
  }
}
