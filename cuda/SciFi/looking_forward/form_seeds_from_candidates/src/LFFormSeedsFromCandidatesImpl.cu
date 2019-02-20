#include "LFFormSeedsFromCandidatesImpl.cuh"

using namespace LookingForward;

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
  const unsigned short second_candidate_l2_size)
{
  const auto first_layer = (station - 1) * 4;

  // We will use this candidate and override it as we go on
  SciFi::TrackCandidate track_candidate {2 * LookingForward::chi2_cut};

  // Convert to global index
  const auto hit_layer_0 = hit_count.event_offset() + first_candidate_index;
  const auto hit_layer_0_x = hits.x0[hit_layer_0];

  for (int i = 0; i < LookingForward::maximum_iteration_l3_window && i < second_candidate_size; i++) {
    const auto hit_layer_3 = hit_count.event_offset() + second_candidate_offset + i;
    const auto hit_layer_3_x = hits.x0[hit_layer_3];
    const auto slope_layer_3_layer_0 = (hit_layer_3_x - hit_layer_0_x) / (LookingForward::dz_x_layers);

    const auto hit_layer_1_idx_chi2 = get_best_hit(
      hits,
      hit_count,
      slope_layer_3_layer_0,
      std::make_tuple(second_candidate_l1_start, second_candidate_l1_size),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer], hit_layer_0_x),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer + 3], hit_layer_3_x),
      dev_looking_forward_constants->Zone_zPos[first_layer + 1],
      y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[first_layer + 1]),
      1,
      dev_looking_forward_constants);

    const auto hit_layer_2_idx_chi2 = get_best_hit(
      hits,
      hit_count,
      slope_layer_3_layer_0,
      std::make_tuple(second_candidate_l2_start, second_candidate_l2_size),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer], hit_layer_0_x),
      std::make_tuple(dev_looking_forward_constants->Zone_zPos[first_layer + 3], hit_layer_3_x),
      dev_looking_forward_constants->Zone_zPos[first_layer + 2],
      y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[first_layer + 2]),
      2,
      dev_looking_forward_constants);

    if ((std::get<0>(hit_layer_1_idx_chi2) != -1) || (std::get<0>(hit_layer_2_idx_chi2) != -1)) {
      unsigned short number_of_hits = 2;
      float quality = 0.f;

      if (std::get<0>(hit_layer_1_idx_chi2) != -1) {
        number_of_hits++;
        quality += std::get<1>(hit_layer_1_idx_chi2);
      }

      if (std::get<0>(hit_layer_2_idx_chi2) != -1) {
        number_of_hits++;
        quality += std::get<1>(hit_layer_2_idx_chi2);
      }

      if (
        number_of_hits > track_candidate.hitsNum ||
        (number_of_hits == track_candidate.hitsNum && quality < track_candidate.quality)) {
        track_candidate = SciFi::TrackCandidate {(short) (hit_layer_0 - hit_count.event_offset()),
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
      }
    }
  }

  if (track_candidate.hitsNum > 2) {
    const int current_insert_index = atomicAdd(track_insert_atomic, 1);

    // There is an upper limit to the tracks we can insert
    if (current_insert_index < SciFi::Constants::max_track_candidates) {
      scifi_track_candidates[current_insert_index] = track_candidate;
    }
  }
}
