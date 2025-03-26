###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB downstream_reconstruction "reconstruction/src/*.cu")
file(GLOB downstream_consolidate "consolidate/src/*.cu")
file(GLOB downstream_vertexing "vertexing/src/*.cu")
file(GLOB downstream_uthits_filter "uthits_filter/src/*.cu")
file(GLOB downstream_consolidate_tracking "consolidate_tracking/src/*.cu")
file(GLOB downstream_tracking "tracking/src/*.cu")

allen_add_device_library(Downstream STATIC
  ${downstream_reconstruction}
  ${downstream_consolidate}
  ${downstream_uthits_filter}
  ${downstream_vertexing}
  ${downstream_tracking}
  ${downstream_consolidate_tracking}
)

target_link_libraries(Downstream PRIVATE Backend HostEventModel EventModel Utils UTCommon)

target_include_directories(Downstream PUBLIC 
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/reconstruction/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uthits_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/vertexing/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tracking/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate_tracking/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>)

target_include_directories(WrapperInterface INTERFACE 
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/reconstruction/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uthits_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/vertexing/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tracking/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate_tracking/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>) 



