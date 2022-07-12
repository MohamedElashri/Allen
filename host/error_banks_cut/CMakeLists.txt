###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_error_bank "src/*cpp")

allen_add_host_library(HostErrorBanks STATIC
  ${host_error_bank}
)

target_link_libraries(HostErrorBanks PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostErrorBanks PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

