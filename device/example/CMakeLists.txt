###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB saxpy_sources "src/*cu")

allen_add_device_library(Examples STATIC
  ${saxpy_sources}
)

target_link_libraries(Examples PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Examples PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
