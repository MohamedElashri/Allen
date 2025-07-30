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
file(GLOB device_validators "src/*cu")

allen_add_device_library(DeviceValidators STATIC
  ${device_validators}
)

target_link_libraries(DeviceValidators PRIVATE
  UTCommon
  Utils
  TrackChecking
  EventModel
  HostEventModel
  SciFi
  Downstream
  Gear
  AllenCommon
  Backend)

target_include_directories(DeviceValidators PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if(ROOT_FOUND)
  # Suppress float->double promotion warnings caused by ROOT TH interfaces
  set_target_properties(DeviceValidators PROPERTIES COMPILE_FLAGS " -Wno-double-promotion ")
endif()
