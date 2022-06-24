###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB lumi_src "src/*cu")

allen_add_device_library(Lumi STATIC
  ${lumi_src}
)

target_link_libraries(Lumi PRIVATE
  AllenCommon
  Backend
  HostEventModel
  EventModel
  Utils
  LHCbEvent
  Kalman
  VertexFitter)

target_include_directories(Lumi PUBLIC
  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/configuration/sequences>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

