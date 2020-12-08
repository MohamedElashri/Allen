###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB generic_tests "generic/src/*cpp")

include_directories(${CMAKE_SOURCE_DIR}/external/Catch2/include)

add_executable(unit_tests ${generic_tests})
target_link_libraries(unit_tests Catch2::Catch2)

include(CTest)
include(Catch)
catch_discover_tests(unit_tests)
