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
file(GLOB blPV "src/*.cu")

allen_add_device_library(PV_beamline STATIC
  ${blPV})

add_library(PVCommon INTERFACE)
target_include_directories(PVCommon INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
install(TARGETS PVCommon EXPORT Allen)

target_link_libraries(PV_beamline PRIVATE PVCommon AllenCommon Backend HostEventModel EventModel Utils)

target_include_directories(PV_beamline PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

add_library(PV_monitoring STATIC src/pv_beamline_monitoring.cpp)
install(TARGETS PV_monitoring EXPORT Allen)

target_include_directories(PV_monitoring PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(PV_monitoring PRIVATE PVCommon AllenCommon)
target_link_libraries(PV_beamline PRIVATE PV_monitoring)
