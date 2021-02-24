###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB tracking_checker_sources "src/*cpp")

allen_add_host_library(TrackChecking STATIC
  ${tracking_checker_sources}
)
target_include_directories(TrackChecking PUBLIC include)
target_link_libraries(TrackChecking PRIVATE HostEventModel EventModel Gear Backend Common Kalman)

find_package(Filesystem)
if(NOT Filesystem_FOUND)
  find_package(Boost COMPONENTS filesystem)
  target_compile_definitions(TrackChecking PRIVATE USE_BOOST_FILESYSTEM)
  target_link_libraries(TrackChecking PRIVATE Boost::filesystem)
else()
  target_link_libraries(TrackChecking PRIVATE std::filesystem)
endif()

if(ROOT_FOUND)
  target_compile_definitions(TrackChecking PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(TrackChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()

if(USE_KALMAN_SINGLE_PRECISION)
  target_compile_definitions(TrackChecking PRIVATE KALMAN_SINGLE_PRECISION)
endif()
