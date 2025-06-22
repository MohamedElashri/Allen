###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

set(mdf_sources
    src/raw_helpers.cpp
    src/read_mdf.cpp
    src/write_mdf.cpp
    src/root_mdf.cpp)

allen_add_host_library(mdf STATIC ${mdf_sources})
target_include_directories (mdf PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/main/include>)

set(lhcb_public_headers
  include/write_mdf.hpp
  include/read_mdf.hpp
  include/mdf_header.hpp
  daq40/sourceid.h)

if (STANDALONE)
  target_link_libraries(mdf PRIVATE LHCbEvent)
else()
  # Interface library for lhcb includes
  add_library(LHCbEvent INTERFACE)
  target_link_libraries(LHCbEvent
    INTERFACE
      Gaudi::GaudiKernel
      LHCb::DAQEventLib
      LHCb::LumiEventLib)

  target_link_libraries(mdf
    PUBLIC
      LHCbEvent
      Boost::filesystem
      Boost::thread
      Boost::regex)
endif()

target_include_directories(LHCbEvent INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/daq40>)

set_property(TARGET LHCbEvent PROPERTY PUBLIC_HEADER ${lhcb_public_headers})
install(TARGETS LHCbEvent EXPORT Allen
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Allen)

target_link_libraries(mdf
  PRIVATE
    Gear
    Backend
    AllenCommon
    LHCbEvent)

# These tests don't need CUDA
remove_definitions(-DTARGET_DEVICE_CUDA)
add_compile_definitions(TARGET_DEVICE_CPU)

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME;SOURCE" "" ${ARGN})
  set(test_name allen_${PARSED_ARGS_NAME})
  add_executable(${test_name} ${PARSED_ARGS_SOURCE})

  find_package(Threads REQUIRED)

  target_link_libraries(${test_name}
    PRIVATE
      HostCommon
      Threads::Threads
      mdf
      Backend
      EventModel
      AllenZMQ
      Catch2::Catch2
      AllenLib
      Boost::program_options
      fmt::fmt)
  target_compile_definitions(${test_name} PRIVATE ODIN_WITHOUT_GAUDI)
  if (NOT STANDALONE)
    target_link_libraries(${test_name} PRIVATE LHCb::DAQEventLib)
  endif()

  install(TARGETS ${test_name} RUNTIME DESTINATION bin)
endfunction()

if (BUILD_TESTING)
  test_program(NAME mdf_test_read SOURCE test/test_read.cpp)
  test_program(NAME mdf_bench_read SOURCE test/bench_read.cpp)
  test_program(NAME mdf_bench_provider SOURCE test/bench_provider.cpp)
  test_program(NAME mdf_bench_transpose SOURCE test/bench_transpose.cpp)

  if (NOT STANDALONE)
    test_program(NAME mep_test_banks SOURCE test/test_mep_banks.cpp)
    target_link_libraries(allen_mep_test_banks PRIVATE Gaudi::GaudiKernel)
  endif()
endif()
