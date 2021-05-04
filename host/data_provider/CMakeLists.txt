###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_data_provider "src/*cpp")

allen_add_host_library(HostDataProvider STATIC
  ${host_data_provider}
)

target_link_libraries(HostDataProvider PRIVATE HostEventModel EventModel Gear Common Backend mdf)

target_include_directories(HostDataProvider PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
