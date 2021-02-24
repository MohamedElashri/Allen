###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_prefix_sum "src/*cpp")

allen_add_host_library(HostPrefixSum STATIC
  ${host_prefix_sum}
)

target_link_libraries(HostPrefixSum PUBLIC HostEventModel EventModel Gear Common Backend)

target_include_directories(HostPrefixSum PUBLIC include)
