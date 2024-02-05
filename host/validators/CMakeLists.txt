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
file(GLOB validators "src/*cpp")

allen_add_host_library(Validators STATIC
  ${validators}
)

target_link_libraries(Validators PRIVATE
  TrackChecking
  SelChecking
  PVChecking
  PV_beamline
  HostEventModel
  EventModel
  SciFi
  HostRoutingBits
  Gear
  AllenCommon
  Backend)

target_include_directories(Validators PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if(ROOT_FOUND)
  # Suppress float->double promotion warnings caused by ROOT TH interfaces
  set_target_properties(Validators PROPERTIES COMPILE_FLAGS " -Wno-double-promotion ")
endif()
