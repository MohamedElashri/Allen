###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB generic_tests "generic/src/*cpp")
file(GLOB cu_generic_tests "generic/src/*cu")

# Make currently configured sequence information available to cpp
add_definitions(-D${TARGET_DEFINITION})

allen_add_executable(unit_tests ${generic_tests} ${cu_generic_tests})

target_link_libraries(unit_tests Catch2::Catch2WithMain HostEventModel EventModel Gear AllenCommon Backend HostCommon)

if (NOT STANDALONE)
  # Make test discovery work in stack builds
  set_property(TARGET unit_tests PROPERTY CROSSCOMPILING_EMULATOR ${CMAKE_BINARY_DIR}/run)
endif()

include(Catch)
catch_discover_tests(unit_tests)

target_include_directories(unit_tests PRIVATE ${PROJECT_BINARY_DIR}/code_generation)

install(TARGETS unit_tests RUNTIME DESTINATION bin)
