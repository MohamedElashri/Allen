###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB tracking_checker_sources "src/*cpp")

allen_add_host_library(TrackChecking STATIC
  ${tracking_checker_sources}
)
target_include_directories(TrackChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(TrackChecking PRIVATE HostEventModel EventModel Gear Backend AllenCommon Kalman)

# TODO: Remove
# Locally suppress float->double promotion warnings caused by ROOT TH interfaces
string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")

if(USE_KALMAN_SINGLE_PRECISION)
  target_compile_definitions(TrackChecking PRIVATE KALMAN_SINGLE_PRECISION)
endif()
