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
file(GLOB host_init_event_list "src/*cpp")

allen_add_host_library(HostInitEventList STATIC
  ${host_init_event_list}
)

target_link_libraries(HostInitEventList PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostInitEventList PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
