###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

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

if (NOT STANDALONE)
  target_link_libraries(Stream PRIVATE Gaudi::GaudiKernel LHCb::DAQEventLib)
endif()

if (USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()

add_dependencies(Stream algorithm_db)

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
