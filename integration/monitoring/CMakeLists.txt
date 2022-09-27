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

# TODO: Remove
# Locally suppress float->double promotion warnings caused by ROOT TH interfaces
string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
