###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB downstream_reconstruction "reconstruction/src/*.cu")
file(GLOB downstream_consolidate "consolidate/src/*.cu")
file(GLOB downstream_uthits_filter "uthits_filter/src/*.cu")

allen_add_device_library(Downstream STATIC
  ${downstream_reconstruction}
  ${downstream_consolidate}
  ${downstream_uthits_filter}
)

target_link_libraries(Downstream PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Downstream PUBLIC 
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/reconstruction/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uthits_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>)

target_include_directories(WrapperInterface INTERFACE 
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/reconstruction/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uthits_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>) 



