###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB device_validators "src/*cu")

allen_add_device_library(DeviceValidators STATIC
  ${device_validators}
)

target_link_libraries(DeviceValidators PRIVATE
  TrackChecking
  EventModel
  HostEventModel
  SciFi
  Gear
  AllenCommon
  Backend)

target_include_directories(DeviceValidators PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if(ROOT_FOUND)
  # Suppress float->double promotion warnings caused by ROOT TH interfaces
  set_target_properties(DeviceValidators PROPERTIES COMPILE_FLAGS " -Wno-double-promotion ")
endif()
