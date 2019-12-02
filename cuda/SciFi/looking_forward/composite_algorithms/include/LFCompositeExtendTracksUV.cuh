#pragma once

#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "LFExtendTracksUV.cuh"
#include "LFSearchUVWindows.cuh"

struct lf_composite_extend_tracks_uv_t : public Algorithm {
  constexpr static auto name {"lf_composite_extend_tracks_uv_t"};
  using Arguments = std::tuple<
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_scifi_lf_x_filtered_tracks,
    dev_scifi_lf_x_filtered_atomics,
    dev_scifi_lf_number_of_candidates,
    dev_scifi_lf_candidates,
    dev_ut_states,
    dev_scifi_lf_uv_windows,
    dev_scifi_lf_initial_windows>;

  using arguments_t = ArgumentRefManager<Arguments>;

  decltype(make_handler("lf_search_uv_windows", lf_search_uv_windows)) handler_lf_search_uv_windows {
    "lf_search_uv_windows",
    lf_search_uv_windows};
  decltype(make_handler("lf_extend_tracks_uv", lf_extend_tracks_uv)) handler_lf_extend_tracks_uv {"lf_extend_tracks_uv",
                                                                                                  lf_extend_tracks_uv};
  
  void invoke();
};
