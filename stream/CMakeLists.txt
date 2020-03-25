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
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/search_initial_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/find_compatible_windows/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_seeding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/triplet_keep_best/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/composite_algorithms/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_first_layers_x/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/extend_tracks_uv/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/quality_filters/include)
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
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/match_upstream_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/patPV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/velo/clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/init_event_list/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/pv/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Postscale/include)
include_directories(${CMAKE_SOURCE_DIR}/mdf/include)
include_directories(${PROJECT_BINARY_DIR}/configuration/sequences)
include_directories(${CPPGSL_INCLUDE_DIR})

if (NOT GaudiProject_FOUND)
  include_directories(${CMAKE_SOURCE_DIR}/mdf/lhcb)
endif()

file(GLOB stream_gear "gear/src/*cpp")
file(GLOB stream_sequence_cpp "sequence/src/*cpp")
file(GLOB stream_sequence "sequence/src/*cu")

# Deal with configuration generation machinery
# Test by actually trying to generate "algorithms.py"
# * If clang is available, we can and will generate the configuration files
# * Otherwise, warn that it is not possible to generate configurations
set(PROJECT_SEQUENCE_DIR ${CMAKE_BINARY_DIR}/sequences)
set(SEQUENCE_DEFINITION_DIR ${PROJECT_SEQUENCE_DIR}/definitions)
set(ALGORITHMS_OUTPUTFILE ${SEQUENCE_DEFINITION_DIR}/algorithms.py)
set(ALGORITHMS_GENERATION_SCRIPT ${CMAKE_SOURCE_DIR}/scripts/ParseAlgorithms.py)
file(MAKE_DIRECTORY ${SEQUENCE_DEFINITION_DIR})

message(STATUS "Testing code generation with LLVM")

# From CMake on execute_process:
# "If a sequential execution of multiple commands is required, use multiple execute_process() calls with a single COMMAND argument."
execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}"
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0
  OUTPUT_VARIABLE ALGORITHMS_GENERATION_OUTPUT
  ERROR_QUIET)
execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}/"
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1
  OUTPUT_VARIABLE ALGORITHMS_GENERATION_OUTPUT
  ERROR_QUIET)
execute_process(COMMAND python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_2
  OUTPUT_VARIABLE ALGORITHMS_GENERATION_OUTPUT
  ERROR_QUIET)
execute_process(COMMAND python3 ${SEQUENCE}.py
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_3
  OUTPUT_VARIABLE ALGORITHMS_GENERATION_OUTPUT
  ERROR_QUIET)

if(${ALGORITHMS_GENERATION_RESULT_0} EQUAL 1 OR ${ALGORITHMS_GENERATION_RESULT_1} EQUAL 1 OR
  ${ALGORITHMS_GENERATION_RESULT_2} EQUAL 1 OR ${ALGORITHMS_GENERATION_RESULT_3} EQUAL 1)
  message(WARNING "Testing code generation with LLVM - Failed. If you want to change the default available configurations, please install clang (minimum version 9.0.0).")
  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.h"
    COMMENT "Configuring sequence ${SEQUENCE}"
    VERBATIM
  )
else()
  message(STATUS "Testing code generation with LLVM - Success")
  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions/*" "${SEQUENCE_DEFINITION_DIR}/" && 
      ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}/" &&
      python3 ${SEQUENCE}.py &&
      ${CMAKE_COMMAND} -E copy "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  )
endif()

allen_add_host_library(HostStream STATIC ${stream_gear} ${stream_sequence_cpp})

allen_add_device_library(Stream STATIC ${stream_sequence})

target_include_directories(Stream INTERFACE "${PROJECT_BINARY_DIR}/configuration/sequences")

add_custom_target(configured_sequence DEPENDS "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h")
add_dependencies(Stream configured_sequence)

target_link_libraries(Stream PRIVATE
  HostStream
  CudaCommon
  Associate
  Velo
  AllenPatPV
  PV_beamline
  HostClustering
  HostPrefixSum
  UT
  Kalman
  VertexFitter
  RawBanks
  SciFi
  HostGEC
  Muon
  Utils)

if (GaudiProject_FOUND)
  find_package(Boost)
  target_include_directories(Stream SYSTEM PUBLIC ${Boost_INCLUDE_DIRS})
endif()

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})

  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
