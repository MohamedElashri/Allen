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
file(GLOB plume_decoding "decoding/src/*cu")

allen_add_device_library(Plume STATIC
  ${plume_decoding}
)

target_link_libraries(Plume PRIVATE AllenCommon Backend HostEventModel EventModel)

target_include_directories(Plume PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/decoding/include>)
