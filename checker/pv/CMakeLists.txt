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
file(GLOB pv_checker_sources "src/*cpp")

allen_add_host_library(PVChecking STATIC
  ${pv_checker_sources}
)
target_include_directories(PVChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(PVChecking PRIVATE HostEventModel EventModel Gear Backend AllenCommon TrackChecking)
