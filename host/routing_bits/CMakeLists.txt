###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_routingbits "src/*cpp")

allen_add_host_library(HostRoutingBits STATIC
  ${host_routingbits}
)
target_link_libraries(HostRoutingBits PUBLIC Boost::headers HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostRoutingBits PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
