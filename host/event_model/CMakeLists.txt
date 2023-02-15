###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_event_model "MC/src/*cpp")

allen_add_host_library(HostEventModel STATIC
  ${host_event_model}
)

target_link_libraries(HostEventModel PRIVATE EventModel Gear AllenCommon Backend)

target_include_directories(HostEventModel PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tae/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MC/include>)
