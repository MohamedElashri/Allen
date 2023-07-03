###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Interface library for lhcb includes
add_library(LHCbEvent INTERFACE)

if (STANDALONE)
  set(odin_files "src/ODIN.cpp" "include/Event/ODIN.h")
else()
  set(odin_files "src/ODIN.cpp")
endif()

foreach(odin_file ${odin_files})
  if (NOT EXISTS "${PROJECT_BINARY_DIR}/imported_${odin_file}")
    file(DOWNLOAD "https://gitlab.cern.ch/lhcb/LHCb/-/raw/master/Event/DAQEvent/${odin_file}"
      "${PROJECT_BINARY_DIR}/imported_${odin_file}"
      STATUS ODIN_DOWNLOAD_STATUS)
    list(POP_FRONT ODIN_DOWNLOAD_STATUS_CODE ODIN_DOWNLOAD_STATUS_MSG)
    if(ODIN_DOWNLOAD_STATUS_CODE)
      message(FATAL_ERROR "Failed to get ${odin_file} copy: ${ODIN_DOWNLOAD_STATUS_MSG}")
    endif()
  endif()
endforeach()

add_library(odin OBJECT ${PROJECT_BINARY_DIR}/imported_src/ODIN.cpp)
target_link_libraries(odin PRIVATE LHCbEvent cppgsl::cppgsl)
target_compile_definitions(odin PRIVATE ODIN_WITHOUT_GAUDI)

set(mdf_sources
    src/raw_helpers.cpp
    src/read_mdf.cpp
    src/write_mdf.cpp
	$<TARGET_OBJECTS:odin>)

list(APPEND mdf_sources src/root_mdf.cpp)

allen_add_host_library(mdf STATIC ${mdf_sources})
target_include_directories (mdf PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/main/include>)
target_link_libraries(mdf PUBLIC LHCbEvent)

set(lhcb_public_headers
  include/write_mdf.hpp
  include/read_mdf.hpp
  include/mdf_header.hpp
  daq40/sourceid.h)
target_include_directories(LHCbEvent INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/daq40>)

if (STANDALONE)
  # Make sure we have a local copy of ODIN.{h,cpp} if building in standalone mode
  target_include_directories(LHCbEvent INTERFACE
    lhcb
    ${PROJECT_BINARY_DIR}/imported_include
    ${PROJECT_BINARY_DIR}/sequences/Gaudi/GaudiKernel/include)
  target_compile_definitions(LHCbEvent INTERFACE ODIN_WITHOUT_GAUDI)
else()
  target_link_libraries(mdf
    PUBLIC
      Boost::filesystem
      Boost::thread
      Boost::regex)
  target_link_libraries(LHCbEvent
    INTERFACE
      Gaudi::GaudiKernel
      LHCb::DAQEventLib
      LHCb::LumiEventLib)
endif()

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
      Transpose
      Threads::Threads
      EventModel
      AllenZMQ
      Catch2::Catch2
      Boost::program_options)
  target_compile_definitions(${test_name} PRIVATE ODIN_WITHOUT_GAUDI)
  if (NOT STANDALONE)
    find_package(fmt REQUIRED)
    target_link_libraries(${test_name} PRIVATE fmt::fmt LHCb::DAQEventLib)
  endif()

  install(TARGETS ${test_name} RUNTIME DESTINATION bin)
endfunction()

if (BUILD_TESTING)
  add_library(Transpose STATIC
    ${PROJECT_SOURCE_DIR}/main/src/Transpose.cpp
    ${PROJECT_SOURCE_DIR}/main/src/Provider.cpp
    ${PROJECT_SOURCE_DIR}/main/src/ZMQOutputSender.cpp)
  target_compile_definitions(Transpose PRIVATE ODIN_WITHOUT_GAUDI)
  target_link_libraries(Transpose
    PUBLIC
      HostCommon
      Backend
      mdf
      LHCbEvent
      AllenZMQ
      EventModel
      AllenFS)

  test_program(NAME mdf_test_read SOURCE test/test_read.cpp)
  test_program(NAME mdf_bench_read SOURCE test/bench_read.cpp)
  test_program(NAME mdf_bench_provider SOURCE test/bench_provider.cpp)
  test_program(NAME mdf_bench_transpose SOURCE test/bench_transpose.cpp)

  if (NOT STANDALONE)
    test_program(NAME mep_test_banks SOURCE test/test_mep_banks.cpp)
    target_link_libraries(allen_mep_test_banks PRIVATE Gaudi::GaudiKernel)
    target_link_libraries(Transpose PUBLIC Configuration)
  endif()

endif()
