include_directories(gear/include)
include_directories(memory_manager/include)
include_directories(scheduler/include)
include_directories(sequence/include)
include_directories(setup/include)
include_directories(checkers/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/muon/include)
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
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Postscale/include)
include_directories(${CMAKE_SOURCE_DIR}/mdf/include)
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
  Selections
  SciFi
  HostGEC
  Muon
  Utils
  Examples
  HostDataProvider
  HostInitEventList)

if (TARGET Gaudi::GaudiKernel)
  get_target_property(GAUDIKERNEL_INCLUDES Gaudi::GaudiKernel INTERFACE_INCLUDE_DIRECTORIES)
  target_include_directories(Stream PUBLIC "${GAUDIKERNEL_INCLUDES}")
endif()

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
