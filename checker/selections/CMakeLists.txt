###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB selection_checker_sources "src/*.cpp")

allen_add_host_library(SelChecking STATIC
  ${selection_checker_sources}
)
set_target_properties(SelChecking PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(SelChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(SelChecking PRIVATE HostEventModel EventModel Gear Backend AllenCommon TrackChecking)
