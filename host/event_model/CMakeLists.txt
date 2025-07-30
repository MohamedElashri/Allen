###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB host_event_model "MC/src/*cpp")

allen_add_host_library(HostEventModel STATIC
  ${host_event_model}
)

target_link_libraries(HostEventModel PRIVATE EventModel Gear AllenCommon Backend)

target_include_directories(HostEventModel PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tae/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MC/include>)
