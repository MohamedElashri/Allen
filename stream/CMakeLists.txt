include_directories(gear/include)
include_directories(memory_manager/include)
include_directories(scheduler/include)
include_directories(sequence/include)
include_directories(setup/include)
include_directories(checkers/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/compassUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/calculate_phi_and_sort/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/consolidate_tracks/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/mask_clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/search_by_triplet/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/simplified_kalman_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/classifiers/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_first_layer_window/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_second_layer_window/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/form_seeds_from_candidates/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_candidate_extrapolation_window/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/promote_candidates/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_track_extrapolation_window/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/search_initial_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/collect_candidates/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/find_compatible_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/triplet_seeding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/triplet_keep_best/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/extend_tracks_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/extend_missing_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/composite_algorithms/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/extend_tracks_first_layers_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/extend_tracks_uv/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/quality_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/quality_filter_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/search_uv_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward_sbt/fit/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/is_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/classification/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding_steps/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/patPV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/velo/clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/SciFi/LookingForward/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/SciFi/MomentumForward/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/pv/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)
include_directories(${PROJECT_BINARY_DIR}/configuration/sequences)

file(GLOB stream_gear "gear/src/*cu")
file(GLOB stream_memory_manager "memory_manager/src/*cu")
file(GLOB stream_scheduler "scheduler/src/*cu")
file(GLOB stream_sequence "sequence/src/*cu")
file(GLOB stream_sequence_cpp "sequence/src/*cpp")
file(GLOB stream_setup "setup/src/*cu")
file(GLOB stream_visitors_gec "visitors/global_event_cut/src/*cu")
file(GLOB stream_visitors_velo "visitors/velo/src/*cu")
file(GLOB stream_visitors_patPV "visitors/patPV/src/*cu")
file(GLOB stream_visitors_beamlinePV "visitors/beamlinePV/src/*cu")
file(GLOB stream_visitors_assoc "visitors/associate/src/*cu")
file(GLOB stream_visitors_UT "visitors/UT/src/*cu")
file(GLOB stream_visitors_SciFi "visitors/SciFi/src/*cu")
file(GLOB stream_visitors_Muon "visitors/muon/src/*cu")
file(GLOB stream_visitors_kalman "visitors/kalman/src/*cu")
file(GLOB stream_visitors_vertex "visitors/vertex_fit/src/*cu")
file(GLOB stream_visitors_selections "visitors/selections/src/*cu")

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    COMMAND cmake -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.h"
)
message(STATUS "Configured sequence: " ${SEQUENCE})

add_library(Stream STATIC
  "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
  ${stream_gear}
  ${stream_memory_manager}
  ${stream_scheduler}
  ${stream_sequence}
  ${stream_sequence_cpp}
  ${stream_setup}
  ${stream_visitors_gec}
  ${stream_visitors_ip}
  ${stream_visitors_velo}
  ${stream_visitors_patPV}
  ${stream_visitors_beamlinePV}
  ${stream_visitors_assoc}
  ${stream_visitors_UT}
  ${stream_visitors_SciFi}
  ${stream_visitors_Muon}
  ${stream_visitors_kalman}
  ${stream_visitors_vertex}
  ${stream_visitors_selections}
)

target_link_libraries(Stream PRIVATE
  Common
  Utils
  Associate
  GlobalEventCut
  Velo
  PatPV
  PV_beamline
  x86Clustering
  x86beamlinePV
  UT
  Kalman
  VertexFitter
  Hlt1
  SciFi
  x86MuonDecoding
  x86LookingForward
  x86MomentumForward
  x86VeloUT
  CpuGEC
  CpuUtils
  Muon)

set_property(TARGET Stream PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})

  target_include_directories(Stream BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
