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
file(GLOB blPV "src/*")

allen_add_device_library(PV_beamline STATIC
  ${blPV})

add_library(PVCommon INTERFACE)
target_include_directories(PVCommon INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
install(TARGETS PVCommon EXPORT Allen)

target_link_libraries(PV_beamline PRIVATE PVCommon AllenCommon Backend HostEventModel EventModel Utils)
target_include_directories(PV_beamline PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
