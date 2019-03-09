file(GLOB scifi_common "common/src/*cu")
file(GLOB scifi_preprocessing "preprocessing/src/*cu")
file(GLOB scifi_lf_common "looking_forward/common/src/*cu")
file(GLOB scifi_lf_calculate_first_layer_window "looking_forward/calculate_first_layer_window/src/*cu")
file(GLOB scifi_lf_calculate_second_layer_window "looking_forward/calculate_second_layer_window/src/*cu")
file(GLOB scifi_lf_form_seeds_from_candidates "looking_forward/form_seeds_from_candidates/src/*cu")
file(GLOB scifi_lf_calculate_candidate_extrapolation_window "looking_forward/calculate_candidate_extrapolation_window/src/*cu")
file(GLOB scifi_lf_promote_candidates "looking_forward/promote_candidates/src/*cu")
file(GLOB scifi_lf_calculate_track_extrapolation_window "looking_forward/calculate_track_extrapolation_window/src/*cu")
file(GLOB scifi_lf_extend_tracks "looking_forward/extend_tracks/src/*cu")
file(GLOB scifi_lf_search_initial_windows "looking_forward_sbt/search_initial_windows/src/*cu")
file(GLOB scifi_lf_collect_candidates "looking_forward_sbt/collect_candidates/src/*cu")
file(GLOB scifi_lf_find_compatible_windows "looking_forward_sbt/find_compatible_windows/src/*cu")
file(GLOB scifi_prforward "PrForward/src/*cu")
file(GLOB scifi_consolidate "consolidate/src/*cu")

include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(common/include)
include_directories(preprocessing/include)
include_directories(looking_forward/common/include)
include_directories(looking_forward/calculate_first_layer_window/include)
include_directories(looking_forward/calculate_second_layer_window/include)
include_directories(looking_forward/form_seeds_from_candidates/include)
include_directories(looking_forward/calculate_candidate_extrapolation_window/include)
include_directories(looking_forward/promote_candidates/include)
include_directories(looking_forward/calculate_track_extrapolation_window/include)
include_directories(looking_forward/extend_tracks/include)
include_directories(looking_forward_sbt/search_initial_windows/include)
include_directories(looking_forward_sbt/collect_candidates/include)
include_directories(looking_forward_sbt/find_compatible_windows/include)
include_directories(PrForward/include)
include_directories(consolidate/include)

add_library(SciFi STATIC
  ${scifi_common}
  ${scifi_preprocessing}
  ${scifi_lf_common}
  ${scifi_lf_calculate_first_layer_window}
  ${scifi_lf_calculate_second_layer_window}
  ${scifi_lf_form_seeds_from_candidates}
  ${scifi_lf_calculate_candidate_extrapolation_window}
  ${scifi_lf_promote_candidates}
  ${scifi_lf_calculate_track_extrapolation_window}
  ${scifi_lf_extend_tracks}
  ${scifi_lf_search_initial_windows}
  ${scifi_lf_collect_candidates}
  ${scifi_lf_find_compatible_windows}
  ${scifi_prforward}
  ${scifi_consolidate}
)

set_property(TARGET SciFi PROPERTY CUDA_SEPARABLE_COMPILATION ON)
