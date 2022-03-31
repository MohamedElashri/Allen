###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB selections_src "Hlt1/src/*cu")
file(GLOB lines_src "lines/calibration/src/*cu" "lines/charm/src/*cu" "lines/inclusive_hadron/src/*cu" "lines/inclusive_hadron/src/*cpp" "lines/muon/src/*cu" "lines/photon/src/*cu" "lines/electron/src/*cu" "lines/monitoring/src/*cu")
allen_add_device_library(Selections STATIC
  ${selections_src}
  ${lines_src}
)

target_link_libraries(Selections PRIVATE
  AllenCommon
  Backend
  HostEventModel
  EventModel
  Utils
  LHCbEvent
  Kalman
  VertexFitter)

if(USE_ROOT)
  # Locally suppress float->double promotion warnings caused by ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()

target_include_directories(Selections PUBLIC
  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/configuration/sequences>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Hlt1/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/calibration/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/monitoring/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/charm/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/inclusive_hadron/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/muon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/electron/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/photon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/line_types/include>)
