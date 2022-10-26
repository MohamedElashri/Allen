###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB host_dummy_maker "src/*cpp")

allen_add_host_library(HostDummyMaker STATIC
  ${host_dummy_maker}
)

target_link_libraries(HostDummyMaker PUBLIC Lumi HostEventModel EventModel Gear AllenCommon Backend)

target_include_directories(HostDummyMaker PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
