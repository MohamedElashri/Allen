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
include_directories(${CMAKE_SOURCE_DIR}/device/utils/tuple_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/muon/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/calo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/compassUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/calculate_phi_and_sort/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/consolidate_tracks/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/mask_clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/search_by_triplet/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/simplified_kalman_filter/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/calo/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/is_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/classification/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/match_upstream_muon/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/patPV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/host/velo/clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/host/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/host/global_event_cut/include)
include_directories(${CMAKE_SOURCE_DIR}/host/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/host/init_event_list/include)
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
include_directories(${PROJECT_BINARY_DIR}/code_generation/include)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

if (NOT GaudiProject_FOUND)
  include_directories(${CMAKE_SOURCE_DIR}/mdf/lhcb)
  include_directories(${PROJECT_BINARY_DIR}/imported_include)
  add_compile_definitions(ODIN_WITHOUT_GAUDI)
endif()

file(GLOB stream_src "sequence/src/*cpp")

allen_add_host_library(Stream STATIC ${stream_src})

include(GenerateConfiguration)

target_include_directories(Stream PRIVATE "${PROJECT_BINARY_DIR}/code_generation/sequences/include")
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
  Validators
  AllenCommon)

# FIXME: this hack will not be needed once all upstream projects are migrated to new cmake configuration
if (TARGET Gaudi::GaudiKernel)
  target_link_libraries(Stream PRIVATE Gaudi::GaudiKernel)
endif()
if (TARGET LHCb::DAQEventLib)
  target_link_libraries(Stream PRIVATE LHCb::DAQEventLib)
endif()

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()

add_dependencies(Stream algorithm_db)

# TODO: In the future a single wrapper script can take care of
# generating the sequence on the fly (using eg. the parsed agorithms pickle)
foreach(sequence ${BUILD_SEQUENCES})
  generate_sequence(${sequence})
  
  # Note this dependency is there only to trigger the .json generation
  add_dependencies(Stream sequence_${sequence})
endforeach()
