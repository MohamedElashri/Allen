###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
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
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/PV/include>)
