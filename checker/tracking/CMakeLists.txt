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
file(GLOB tracking_checker_sources "src/*cpp")

allen_add_host_library(TrackChecking STATIC
  ${tracking_checker_sources}
)
target_include_directories(TrackChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(TrackChecking PRIVATE HostEventModel EventModel Gear Backend AllenCommon)

if(USE_KALMAN_SINGLE_PRECISION)
  target_compile_definitions(TrackChecking PRIVATE KALMAN_SINGLE_PRECISION)
endif()
