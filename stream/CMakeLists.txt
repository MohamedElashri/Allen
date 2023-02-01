###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
include(GenerateConfiguration)

# Gear interface library
add_library(Gear INTERFACE)
target_include_directories(Gear INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/gear/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/store/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sequence/include>)
target_link_libraries(Gear INTERFACE Boost::boost)
install(TARGETS Gear EXPORT Allen)

file(GLOB stream_src "sequence/src/*cpp")

allen_add_host_library(Stream STATIC ${stream_src})

target_link_libraries(Stream
  PRIVATE
    HostClustering
    HostDataProvider
    HostDummyMaker
    HostErrorBanks
    HostGEC
    HostInitEventList
    HostPrefixSum
    HostRoutingBits
    HostTAEFilter
    AllenCommon
    Associate
    Backend
    Calo
    Combiners
    DeviceValidators
    Examples
    Kalman
    Lumi
    Muon
    PV_beamline
    Plume
    SciFi
    UT
    Validators
    Velo
    VertexFitter
    algorithm_db
    track_matching
  PUBLIC
    Utils
    Selections)

add_dependencies(Stream generate_algorithms_view)
if(STANDALONE)
  add_dependencies(Stream checkout_lhcb checkout_gaudi)
endif()

foreach(sequence ${BUILD_SEQUENCES})
  generate_sequence(${sequence})
endforeach()
