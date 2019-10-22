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
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/search_initial_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/collect_candidates/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/find_compatible_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_seeding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_keep_best/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_missing_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/composite_algorithms/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_first_layers_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_uv/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/quality_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/quality_filter_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/search_uv_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/fit/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/calculate_parametrization/include)
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
include_directories(${CMAKE_SOURCE_DIR}/x86/velo/clustering/include)
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
file(GLOB stream_visitors_SciFi_decoding "visitors/SciFi/decoding/src/*cu")
file(GLOB stream_visitors_SciFi_looking_forward "visitors/SciFi/looking_forward/src/*cu")
file(GLOB stream_visitors_Muon "visitors/muon/src/*cu")
file(GLOB stream_visitors_kalman "visitors/kalman/src/*cu")
file(GLOB stream_visitors_vertex "visitors/vertex_fit/src/*cu")
file(GLOB stream_visitors_selections "visitors/selections/src/*cu")

add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.h"
)

message(STATUS "Configured sequence: " ${SEQUENCE})

if(TARGET_DEVICE STREQUAL "CPU")
  foreach(source_file ${stream_gear} ${stream_memory_manager} ${stream_scheduler}
    ${stream_sequence} ${stream_sequence_cpp} ${stream_setup} ${stream_visitors_gec}
    ${stream_visitors_ip} ${stream_visitors_velo} ${stream_visitors_patPV}
    ${stream_visitors_beamlinePV} ${stream_visitors_assoc} ${stream_visitors_UT}
    ${stream_visitors_SciFi_decoding} ${stream_visitors_SciFi_looking_forward}
    ${stream_visitors_Muon} ${stream_visitors_kalman}
    ${stream_visitors_vertex} ${stream_visitors_selections})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_library(Visitors STATIC
  ${stream_visitors_gec}
  ${stream_visitors_ip}
  ${stream_visitors_velo}
  ${stream_visitors_patPV}
  ${stream_visitors_beamlinePV}
  ${stream_visitors_assoc}
  ${stream_visitors_UT}
  ${stream_visitors_SciFi_decoding}
  ${stream_visitors_SciFi_looking_forward}
  ${stream_visitors_Muon}
  ${stream_visitors_kalman}
  ${stream_visitors_vertex}
  ${stream_visitors_selections}
)

target_link_libraries(Visitors PRIVATE
  CudaCommon
  Associate
  GlobalEventCut
  Velo
  AllenPatPV
  PV_beamline
  x86Clustering
  UT
  Kalman
  VertexFitter
  Hlt1
  SciFi
  CpuGEC
  CpuUtils
  Muon
  Utils)

# Avoid unused parameter warnings in Visitors
if(TARGET_DEVICE STREQUAL "CUDA")
  target_compile_options(Visitors PRIVATE "-Xcompiler=-Wno-unused-parameter")
else()
  target_compile_options(Visitors PRIVATE "-Wno-unused-parameter")
endif()

allen_add_library(Stream STATIC
  "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
  ${stream_gear}
  ${stream_memory_manager}
  ${stream_scheduler}
  ${stream_sequence}
  ${stream_sequence_cpp}
  ${stream_setup}
)

target_link_libraries(Stream PRIVATE
  CudaCommon
  Associate
  GlobalEventCut
  Velo
  AllenPatPV
  PV_beamline
  x86Clustering
  UT
  Kalman
  VertexFitter
  Hlt1
  SciFi
  CpuGEC
  CpuUtils
  Muon
  Utils
  Visitors)

set_property(TARGET Stream PROPERTY CUDA_RESOLVE_DEVICE_SYMBOLS ON)

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})

  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
