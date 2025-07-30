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
file(GLOB kalman_ParKalman "ParKalman/src/*cu")

allen_add_device_library(Kalman STATIC
  ${kalman_ParKalman}
)

target_link_libraries(Kalman PUBLIC SciFi Associate
  PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Kalman PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ParKalman/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../PV/beamlinePV/include>)

target_include_directories(WrapperInterface INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ParKalman/include>)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
