###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
allen_add_host_library(HostTAEFilter STATIC
  src/HostTAEFilter.cpp
)

target_link_libraries(HostTAEFilter PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostTAEFilter PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
