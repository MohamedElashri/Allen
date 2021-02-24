###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB UT_decoding "UTDecoding/src/*cu")
file(GLOB UT_consolidate "consolidate/src/*cu")
file(GLOB CompassUT_tracking "compassUT/src/*cu")

allen_add_device_library(UT STATIC
  ${UT_decoding}
  ${UT_consolidate}
  ${CompassUT_tracking}
)

target_link_libraries(UT PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(UT PUBLIC
  common/include
  UTDecoding/include
  consolidate/include
  compassUT/include)
