#include "LFFormSeedsFromCandidatesImpl.cuh"

using namespace LookingForward;

__device__ void insert_candidate(SciFi::TrackCandidate* shared_candidates, const SciFi::TrackCandidate& candidate)
{
  int worst_candidate = LookingForward::form_seeds_x_threads;
  int hitsNum = shared_candidates[worst_candidate].hitsNum;
  float quality = shared_candidates[worst_candidate].quality;

  for (int i = 1; i < LookingForward::form_seeds_candidates_per_thread; ++i) {
    const auto index = i * LookingForward::form_seeds_x_threads;

    if (
      shared_candidates[index].hitsNum < hitsNum ||
      (shared_candidates[index].hitsNum == hitsNum && shared_candidates[index].quality > quality)) {
      worst_candidate = index;
      hitsNum = shared_candidates[index].hitsNum;
      quality = shared_candidates[index].quality;
    }
  }

  if (candidate.hitsNum > hitsNum || (candidate.hitsNum == hitsNum && candidate.quality < quality)) {
    shared_candidates[worst_candidate] = candidate;
  }
};

__device__ void lf_form_seeds_from_candidates_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const unsigned short rel_ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates,
  const unsigned short first_candidate_index,
  const unsigned short second_candidate_offset,
  const unsigned short second_candidate_size,
  const unsigned short second_candidate_l1_start,
  const unsigned short second_candidate_l1_size,
  const unsigned short second_candidate_l2_start,
  const unsigned short second_candidate_l2_size,
  SciFi::TrackCandidate* shared_track_candidates)
{
  __syncthreads();

  for (int i = threadIdx.x; i < LookingForward::form_seeds_candidates_per_thread *
                                  LookingForward::form_seeds_x_threads;
       i += blockDim.x) {
    shared_track_candidates[i].quality = 2 * LookingForward::chi2_cut;
    shared_track_candidates[i].hitsNum = 0;
  }

  __syncthreads();

  const auto first_layer = (station - 1) * 4;

  // Upper limit of tracks to add
  int number_of_considered_tracks = 0;

  // There is an upper limit of the tracks we can add
  bool track_limit_surpassed = false;

  const auto z_mag = dev_looking_forward_constants->zMagnetParams[0];
  const auto x_mag = x_at_z(velo_ut_state, z_mag);
  const auto y_mag = y_at_z(velo_ut_state, z_mag);

  // Convert to global index
  const auto hit_layer_0 = hit_count.event_offset() + first_candidate_index;
  const auto hit_layer_0_x = hits.x0[hit_layer_0];

  for (int i = threadIdx.y;
       !track_limit_surpassed && number_of_considered_tracks < LookingForward::maximum_considered_tracks_per_thread &&
       i < second_candidate_size;
       i += blockDim.y) {
    const auto hit_layer_3 = hit_count.event_offset() + second_candidate_offset + i;
    const auto hit_layer_3_x = hits.x0[hit_layer_3];

    const auto slope_layer_3_layer_0 = (hit_layer_3_x - hit_layer_0_x) / (LookingForward::dz_x_layers);

    const auto hit_layer_1_idx_chi2 = get_best_hit(
      hits,
      slope_layer_3_layer_0,
      std::make_tuple(second_candidate_l1_start, second_candidate_l1_start + second_candidate_l1_size),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer], hit_layer_0_x),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer + 3], hit_layer_3_x),
      dev_looking_forward_constants->Zone_zPos[first_layer + 1],
      y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[first_layer + 1]),
      1,
      dev_looking_forward_constants);

    const auto hit_layer_2_idx_chi2 = get_best_hit(
      hits,
      slope_layer_3_layer_0,
      std::make_tuple(second_candidate_l2_start, second_candidate_l2_start + second_candidate_l2_size),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer], hit_layer_0_x),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer + 3], hit_layer_3_x),
      dev_looking_forward_constants->Zone_zPos[first_layer + 2],
      y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[first_layer + 2]),
      2,
      dev_looking_forward_constants);

    if ((std::get<0>(hit_layer_1_idx_chi2) != -1) || (std::get<0>(hit_layer_2_idx_chi2) != -1)) {
      number_of_considered_tracks++;

      auto track_candidate = SciFi::TrackCandidate {(short) (hit_layer_0 - hit_count.event_offset()),
                                                  (short) (hit_layer_3 - hit_count.event_offset()),
                                                  rel_ut_track_index,
                                                  ut_qop};

      if (std::get<0>(hit_layer_1_idx_chi2) != -1) {
        track_candidate.add_hit_with_quality(
          (short) (std::get<0>(hit_layer_1_idx_chi2) - hit_count.event_offset()), std::get<1>(hit_layer_1_idx_chi2));
      }

      if (std::get<0>(hit_layer_2_idx_chi2) != -1) {
        track_candidate.add_hit_with_quality(
          ((short) std::get<0>(hit_layer_2_idx_chi2) - hit_count.event_offset()), std::get<1>(hit_layer_2_idx_chi2));
      }
      
      insert_candidate(shared_track_candidates, track_candidate);
    }
  }

  __syncthreads();

  // TODO

  // const int current_insert_index = atomicAdd(track_insert_atomic, 1);

  // // There is an upper limit to the tracks we can insert
  // if (current_insert_index < SciFi::Constants::max_track_candidates) {
  //   auto track_candidate = SciFi::TrackCandidate {(short) (hit_layer_0 - hit_count.event_offset()),
  //                                                 (short) (hit_layer_3 - hit_count.event_offset()),
  //                                                 rel_ut_track_index,
  //                                                 ut_qop};

  //   if (std::get<0>(hit_layer_1_idx_chi2) != -1) {
  //     track_candidate.add_hit_with_quality(
  //       (short) (std::get<0>(hit_layer_1_idx_chi2) - hit_count.event_offset()), std::get<1>(hit_layer_1_idx_chi2));
  //   }

  //   if (std::get<0>(hit_layer_2_idx_chi2) != -1) {
  //     track_candidate.add_hit_with_quality(
  //       ((short) std::get<0>(hit_layer_2_idx_chi2) - hit_count.event_offset()), std::get<1>(hit_layer_2_idx_chi2));
  //   }

  //   scifi_track_candidates[current_insert_index] = track_candidate;
  // }
  // else {
  //   track_limit_surpassed = true;
  // }
}
