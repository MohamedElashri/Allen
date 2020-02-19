###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
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
include_directories(${CMAKE_SOURCE_DIR}/cuda/calo/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/calo/event_model/include)
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
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/vertex_fitter/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/line_types/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/lines/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Postscale/include)
include_directories(${CMAKE_SOURCE_DIR}/mdf/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${PROJECT_BINARY_DIR}/configuration/sequences)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

if (NOT GaudiProject_FOUND)
  include_directories(${CMAKE_SOURCE_DIR}/mdf/lhcb)
endif()

file(GLOB stream_gear "gear/src/*cpp")
file(GLOB stream_sequence_cpp "sequence/src/*cpp")

include(GenerateConfiguration)

allen_add_host_library(Stream STATIC ${stream_gear} ${stream_sequence_cpp})

# Set property of compiling only this one object concurrently (ninja)
# Rationale: Stream.cpp alone requires GBs to compile and may result otherwise in killing the build job.
set_property(GLOBAL APPEND PROPERTY JOB_POOLS one_job=1)
set_property(TARGET Stream PROPERTY JOB_POOL_COMPILE one_job)

target_include_directories(Stream INTERFACE "${PROJECT_BINARY_DIR}/configuration/sequences")

# Depend of Sequence.json instead of configuration/sequences/ConfiguredSequence.h.
# By doing this, if the ${SEQUENCE}.py changes, a re-configuration will be triggered.
# The json will always be updated, satisfying the dependence and not triggering a re-configuration
# until the ${SEQUENCE}.py changes again.
# However, since the Sequence.h is only copied *if different*, this will not necessarily trigger a re-compilation.
# In other words, the timestamp of Sequence.json is used to keep up with that of ${SEQUENCE}.py.
add_custom_target(configured_sequence DEPENDS "${PROJECT_BINARY_DIR}/Sequence.json")
add_dependencies(Stream configured_sequence)

target_link_libraries(Stream PRIVATE
  Associate
  Velo
  AllenPatPV
  PV_beamline
  HostClustering
  HostPrefixSum
  UT
  Kalman
  VertexFitter
  Selections
  SciFi
  HostGEC
  Calo
  Muon
  Utils
  Examples
  HostDataProvider
  HostInitEventList
  Backend
  Validators)

# FIXME: this hack will not be needed once all upstream projects are migrated to new cmake configuration
if (TARGET Gaudi::GaudiKernel)
  target_link_libraries(Stream PRIVATE Gaudi::GaudiKernel)
endif()

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
