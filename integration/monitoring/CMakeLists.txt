###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB monitoring_sources_cpp "src/*cpp")

allen_add_host_library(Monitoring STATIC
  ${monitoring_sources_cpp}
)

target_link_libraries(Monitoring PRIVATE AllenZMQ Gear Backend VertexFitter EventModel
  Selections)

target_include_directories(Monitoring PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if (NOT STANDALONE)
  target_compile_definitions(Monitoring PUBLIC GAUDI_BUILD)
  target_link_libraries(Monitoring PRIVATE Gaudi::GaudiUtilsLib)
endif()

if(ROOT_FOUND)
  target_compile_definitions(Monitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Monitoring PRIVATE SYSTEM
    ${ROOT_INCLUDE_DIRS}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()
