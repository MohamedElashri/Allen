###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB combiners_src "src/*cu")

allen_add_device_library(Combiners STATIC
  ${combiners_src}
)

target_link_libraries(Combiners PUBLIC VertexFitter PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Combiners PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)