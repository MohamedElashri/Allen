###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_routingbits_configuration "src/*cpp")

allen_add_host_library(HostRoutingBitsConfiguration STATIC
  ${host_routingbits_configuration}
)
target_link_libraries(HostRoutingBitsConfiguration PUBLIC HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostRoutingBitsConfiguration PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
