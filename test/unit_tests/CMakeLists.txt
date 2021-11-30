###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB generic_tests "generic/src/*cpp")
file(GLOB cu_generic_tests "generic/src/*cu")

# Make currently configured sequence information available to cpp
add_definitions(-D${TARGET_DEFINITION})

allen_add_executable(unit_tests ${generic_tests} ${cu_generic_tests})

target_link_libraries(unit_tests Catch2::Catch2 HostPrefixSum)

if (NOT STANDALONE)
  # Make test discovery work in stack builds
  set_property(TARGET unit_tests PROPERTY CROSSCOMPILING_EMULATOR ${CMAKE_BINARY_DIR}/run)
endif()

include(Catch)
catch_discover_tests(unit_tests)

install(TARGETS unit_tests RUNTIME DESTINATION bin)
