###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB calo_decoding "decoding/src/*cu")
file(GLOB calo_clustering "clustering/src/*cu")
file(GLOB tools "tools/src/*cu")

allen_add_device_library(Calo STATIC
  ${calo_decoding}
  ${calo_clustering}
  ${tools}
)

target_link_libraries(Calo PRIVATE AllenCommon Backend HostEventModel EventModel)

target_include_directories(Calo PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/decoding/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tools/include>)
