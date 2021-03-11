###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB generic_tests "generic/src/*cpp")
file(GLOB cu_generic_tests "generic/src/*cu")

include_directories(${CMAKE_SOURCE_DIR}/external/Catch2/single_include/catch2)
include_directories(${CMAKE_SOURCE_DIR}/host/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(generic/include)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

# Make currently configured sequence information available to cpp
add_definitions(-D${TARGET_DEFINITION})

allen_add_executable(unit_tests ${generic_tests} ${cu_generic_tests})

target_link_libraries(unit_tests Catch2::Catch2 HostPrefixSum)

if (NOT STANDALONE)
  # Make test discovery work in stack builds
  set_property(TARGET unit_tests PROPERTY CROSSCOMPILING_EMULATOR ${env_cmd} --xml ${env_xml})
endif()

include(CTest)
include(Catch)
catch_discover_tests(unit_tests)

install(TARGETS unit_tests RUNTIME DESTINATION bin)
