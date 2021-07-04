###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

include(GenerateConfiguration)

set_property(GLOBAL APPEND PROPERTY JOB_POOLS sequence_job=${SEQUENCE_BUILD_JOBS})

foreach(sequence ${BUILD_SEQUENCES})

  generate_sequence(${sequence})

  set(${sequence}_sources src/Stream.cpp)
  get_property(stream_dependent_sources GLOBAL PROPERTY STREAM_DEPENDENT_SOURCES)
  if (stream_dependent_sources)
    foreach(source ${stream_dependent_sources})
      list(APPEND ${sequence}_sources ${source})
    endforeach()
  endif()

  allen_add_device_library(Stream_${sequence} SHARED ${${sequence}_sources} STREAM)

  # Set property of compiling only this one object concurrently (ninja)
  # Rationale: Stream.cpp alone requires GBs to compile and may result otherwise in killing the build job.
  set_property(TARGET Stream_${sequence} PROPERTY JOB_POOL_COMPILE sequence_job)

  target_include_directories(Stream_${sequence} PRIVATE "${PROJECT_BINARY_DIR}/sequences/${sequence}")
  target_link_libraries(Stream_${sequence} PRIVATE
    StreamUtils
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
    target_link_libraries(Stream_${sequence} PRIVATE Gaudi::GaudiKernel)
  endif()
  if (TARGET LHCb::DAQEventLib)
    target_link_libraries(Stream_${sequence} PRIVATE LHCb::DAQEventLib)
  endif()

  if (ROOT_FOUND)
    target_compile_definitions(Stream_${sequence} PUBLIC ${ALLEN_ROOT_DEFINITIONS})
    target_include_directories(Stream_${sequence} SYSTEM BEFORE PRIVATE
      ${ROOT_INCLUDE_DIRS}
    )
  endif()

  add_custom_target(configured_${sequence} DEPENDS "${PROJECT_BINARY_DIR}/code_generation/configuration/sequences/ConfiguredSequence.h")
  add_dependencies(Stream_${sequence} configured_${sequence})
endforeach()
