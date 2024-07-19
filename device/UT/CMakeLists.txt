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
file(GLOB UT_decoding "UTDecoding/src/*cu")
file(GLOB UT_consolidate "consolidate/src/*cu")
file(GLOB CompassUT_tracking "compassUT/src/*cu")
file(GLOB UT_FilterUsedHits "FilterUsedHits/src/*cu")

add_library(UTCommon INTERFACE)
target_include_directories(UTCommon INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>)
install(TARGETS UTCommon EXPORT Allen)

allen_add_device_library(UT STATIC
  ${UT_decoding}
  ${UT_consolidate}
  ${CompassUT_tracking}
  ${UT_FilterUsedHits}
)

target_link_libraries(UT
  PUBLIC
    UTCommon
  PRIVATE
    Backend
    HostEventModel
    EventModel
    Utils)

target_include_directories(UT PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/UTDecoding/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FilterUsedHits/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/compassUT/include>)

target_link_libraries(WrapperInterface INTERFACE UTCommon)
