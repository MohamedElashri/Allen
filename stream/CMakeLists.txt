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
target_link_libraries(Gear INTERFACE struct_to_tuple)
install(TARGETS Gear EXPORT Allen)

file(GLOB stream_src "sequence/src/*cpp")

allen_add_host_library(Stream STATIC ${stream_src})

target_link_libraries(Stream
  PRIVATE
    Associate
    Velo
    PV_beamline
    HostClustering
    HostPrefixSum
    UT
    Kalman
    VertexFitter
    SciFi
    HostGEC
    Calo
    Muon
    Examples
    HostDataProvider
    HostInitEventList
    Backend
    Validators
    DeviceValidators
    AllenCommon
    algorithm_db
  PUBLIC
    Utils
    Selections)

# In STANDALONE, the following dependencies will make runtime sequence generation work
# even if SEQUENCES was empty.
if(STANDALONE)
  add_dependencies(Stream checkout_gaudi_dirs generate_algorithms_view)
endif()

# TODO: In the future a single wrapper script can take care of
# generating the sequence on the fly (using eg. the parsed agorithms pickle)
foreach(sequence ${BUILD_SEQUENCES})
  generate_sequence(${sequence})
endforeach()
