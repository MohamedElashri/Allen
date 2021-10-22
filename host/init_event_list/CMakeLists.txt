###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_init_event_list "src/*cpp")

allen_add_host_library(HostInitEventList STATIC
  ${host_init_event_list}
)

target_link_libraries(HostInitEventList PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostInitEventList PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
