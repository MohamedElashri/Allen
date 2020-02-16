file(GLOB scifi_common "common/src/*cu")
file(GLOB scifi_preprocessing "preprocessing/src/*cu")
file(GLOB scifi_lf_common "looking_forward/common/src/*cu")
file(GLOB scifi_lf_search_initial_windows "looking_forward/search_initial_windows/src/*cu")
file(GLOB scifi_lf_extend_tracks_x "looking_forward/extend_tracks_x/src/*cu")
file(GLOB scifi_lf_triplet_seeding "looking_forward/triplet_seeding/src/*cu")
file(GLOB scifi_lf_triplet_keep_best "looking_forward/triplet_keep_best/src/*cu")
file(GLOB scifi_lf_extend_tracks_uv "looking_forward/extend_tracks_uv/src/*cu")
file(GLOB scifi_lf_quality_filters "looking_forward/quality_filters/src/*cu")
file(GLOB scifi_lf_fit "looking_forward/fit/src/*cu")
file(GLOB scifi_consolidate "consolidate/src/*cu")
file(GLOB scifi_lf_calculate_parametrization "looking_forward/calculate_parametrization/src/*cu")

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
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/SciFi/LookingForward/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/SciFi/MomentumForward/include)
include_directories(common/include)
include_directories(preprocessing/include)
include_directories(looking_forward/common/include)
include_directories(looking_forward/search_initial_windows/include)
include_directories(looking_forward/extend_tracks_x/include)
include_directories(looking_forward/triplet_seeding/include)
include_directories(looking_forward/triplet_keep_best/include)
include_directories(looking_forward/extend_tracks_uv/include)
include_directories(looking_forward/quality_filters/include)
include_directories(looking_forward/fit/include)
include_directories(looking_forward/calculate_parametrization/include)
include_directories(consolidate/include)
include_directories(${CPPGSL_INCLUDE_DIR})

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  foreach(source_file ${scifi_common} ${scifi_preprocessing}
    ${scifi_lf_common} ${scifi_lf_calculate_first_layer_window}
    ${scifi_lf_calculate_second_layer_window} ${scifi_lf_form_seeds_from_candidates}
    ${scifi_lf_calculate_candidate_extrapolation_window} ${scifi_lf_promote_candidates}
    ${scifi_lf_calculate_track_extrapolation_window} ${scifi_lf_extend_tracks}
    ${scifi_lf_search_initial_windows} ${scifi_lf_collect_candidates}
    ${scifi_lf_extend_tracks_x} ${scifi_lf_triplet_seeding}
    ${scifi_lf_triplet_keep_best} ${scifi_lf_extend_tracks_uv} ${scifi_lf_quality_filters}
    ${scifi_consolidate} ${scifi_lf_calculate_parametrization}
    ${scifi_lf_fit})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_device_library(SciFi STATIC
  ${scifi_common}
  ${scifi_preprocessing}
  ${scifi_lf_common}
  ${scifi_lf_search_initial_windows}
  ${scifi_lf_extend_tracks_x}
  ${scifi_lf_triplet_seeding}
  ${scifi_lf_triplet_keep_best}
  ${scifi_lf_extend_tracks_uv}
  ${scifi_lf_quality_filters}
  ${scifi_consolidate}
  ${scifi_lf_calculate_parametrization}
  ${scifi_lf_fit}
)
