###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB generic_tests "generic/src/*cpp")

include_directories(${CMAKE_SOURCE_DIR}/external/Catch2/single_include/catch2)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(generic/include)

# Make currently configured sequence information available to cpp
add_definitions(-DSEQUENCE="${SEQUENCE}")

add_executable(unit_tests ${generic_tests})
target_link_libraries(unit_tests Catch2::Catch2 AllenLib)

include(CTest)
include(Catch)
catch_discover_tests(unit_tests)

install(TARGETS unit_tests RUNTIME DESTINATION bin)
