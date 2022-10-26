###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
add_library(EventModel INTERFACE)
install(TARGETS EventModel EXPORT Allen)

target_include_directories(EventModel INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/associate/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/calo/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/muon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/SciFi/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/selections/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/UT/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/velo/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/kalman/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/vertex_fit/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/PV/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lumi/include>)

target_link_libraries(EventModel INTERFACE AllenCommon)
