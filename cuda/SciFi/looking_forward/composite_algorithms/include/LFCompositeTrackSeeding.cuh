#pragma once

#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "LFTripletSeeding.cuh"
#include "LFExtendTracksX.cuh"
#include "LFTripletKeepBest.cuh"

// #define COMPOSITE_ALGORITHM(FUNCTIONS, EXPOSED_TYPE_NAME, DEPENDENCIES)
//   struct EXPOSED_TYPE_NAME {
//     constexpr static auto name {#EXPOSED_TYPE_NAME};
//     using Arguments = DEPENDENCIES;
//     using arguments_t = ArgumentRefManager<Arguments>;
//     decltype(composite_handler(FUNCTIONS)) handlers {composite_handler(FUNCTIONS)};
//   };

struct lf_composite_track_seeding_t : public Algorithm {
  constexpr static auto name {"lf_composite_track_seeding_t"};
  using Arguments = std::tuple<
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_qop,
    dev_ut_states,
    dev_scifi_lf_number_of_candidates,
    dev_scifi_lf_candidates,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_triplet_best>;

  using arguments_t = ArgumentRefManager<Arguments>;

  decltype(make_handler("lf_triplet_seeding", lf_triplet_seeding)) handler_lf_triplet_seeding {"lf_triplet_seeding",
                                                                                               lf_triplet_seeding};
  decltype(make_handler("lf_triplet_keep_best", lf_triplet_keep_best)) handler_lf_triplet_keep_best {
    "lf_triplet_keep_best",
    lf_triplet_keep_best};
  decltype(make_handler("lf_extend_tracks_x", lf_extend_tracks_x)) handler_lf_extend_tracks_x {"lf_extend_tracks_x",
                                                                                               lf_extend_tracks_x};

  void invoke();
};

// COMPOSITE_ALGORITHM(
//   lf_triplet_seeding,
//   lf_triplet_seeding_t,
//   ARGUMENTS(
//     dev_scifi_hits,
//     dev_scifi_hit_count,
//     dev_atomics_ut,
//     dev_ut_qop,
//     dev_ut_states,
//     dev_scifi_lf_number_of_candidates,
//     dev_scifi_lf_candidates,
//     dev_scifi_tracks,
//     dev_atomics_scifi,
//     dev_scifi_lf_candidate_atomics,
//     dev_scifi_lf_candidates_flag))
