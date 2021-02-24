###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB prefix_sum "prefix_sum/src/*cu")

allen_add_device_library(Utils STATIC
  ${prefix_sum}
)

target_link_libraries(Utils PRIVATE Backend EventModel)

target_include_directories(Utils PUBLIC
  prefix_sum/include
  binary_search/include
  sorting/include
  float_operations/include)
