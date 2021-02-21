###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB velo_prefix_sum "prefix_sum/src/*cu")
file(GLOB velo_clustering_sources "mask_clustering/src/*cu")
file(GLOB velo_search_by_triplet "search_by_triplet/src/*cu")
file(GLOB velo_simplified_kalman_filter "simplified_kalman_filter/src/*cu")
file(GLOB velo_consolidate_tracks "consolidate_tracks/src/*cu")

allen_add_device_library(Velo STATIC
  ${velo_clustering_sources}
  ${velo_prefix_sum}
  ${velo_search_by_triplet}
  ${velo_simplified_kalman_filter}
  ${velo_consolidate_tracks}
)

target_link_libraries(Velo PRIVATE Backend EventModel Utils)

target_include_directories(Velo PUBLIC
  common/include
  prefix_sum/include
  mask_clustering/include
  calculate_phi_and_sort/include
  search_by_triplet/include
  simplified_kalman_filter/include
  consolidate_tracks/include)
