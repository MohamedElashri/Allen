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

target_link_libraries(Velo PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Velo PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/prefix_sum/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/mask_clustering/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/calculate_phi_and_sort/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/search_by_triplet/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/simplified_kalman_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate_tracks/include>)

target_include_directories(WrapperInterface INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>)
