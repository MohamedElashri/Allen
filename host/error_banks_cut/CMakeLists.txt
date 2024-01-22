###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
allen_add_host_library(HostErrorBanks STATIC
  src/HostOdinErrorFilter.cpp
  src/ErrorBankFilter.cpp
)

target_link_libraries(HostErrorBanks PRIVATE HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostErrorBanks PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
