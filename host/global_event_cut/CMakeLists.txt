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
set(host_gec_sources
  "src/HostSciFiGEC.cpp"
  "src/HostUTGEC.cpp")

allen_add_host_library(HostGEC STATIC
  ${host_gec_sources}
)

target_link_libraries(HostGEC PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostGEC PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/device/SciFi/common/include>)
