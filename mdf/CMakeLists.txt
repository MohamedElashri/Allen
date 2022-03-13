###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Interface library for lhcb includes
add_library(LHCbEvent INTERFACE)

set(mdf_sources
    src/raw_helpers.cpp
    src/read_mdf.cpp
    src/write_mdf.cpp)

if (ROOT_FOUND AND USE_ROOT)
  list(APPEND mdf_sources src/root_mdf.cpp)
endif()

allen_add_host_library(mdf STATIC ${mdf_sources})
target_include_directories (mdf PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/main/include>)
target_link_libraries(mdf PUBLIC LHCbEvent)

set(lhcb_public_headers include/write_mdf.hpp include/read_mdf.hpp include/mdf_header.hpp daq40/sourceid.h)
target_include_directories(LHCbEvent INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/daq40>)

if (STANDALONE)
  # Make sure we have a local copy of ODIN.{h,cpp} if building in standalone mode
  set(odin_files "src/ODIN.cpp" "include/Event/ODIN.h")
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
  list(APPEND mdf_sources ${PROJECT_BINARY_DIR}/imported_src/ODIN.cpp)
  target_sources(mdf PRIVATE ${mdf_sources})
  target_include_directories(LHCbEvent INTERFACE
    lhcb
    ${PROJECT_BINARY_DIR}/imported_include
    ${PROJECT_BINARY_DIR}/sequences/Gaudi/GaudiKernel/include)
  target_compile_definitions(LHCbEvent INTERFACE ODIN_WITHOUT_GAUDI)
else()
  target_link_libraries(mdf PUBLIC Boost::filesystem Boost::thread Boost::regex)
  target_link_libraries(LHCbEvent INTERFACE Gaudi::GaudiKernel LHCb::DAQEventLib)
endif()

set_property(TARGET LHCbEvent PROPERTY PUBLIC_HEADER ${lhcb_public_headers})
install(TARGETS LHCbEvent EXPORT Allen
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Allen)

target_link_libraries(
  mdf PRIVATE Gear Backend AllenCommon LHCbEvent)

# These tests don't need CUDA
remove_definitions(-DTARGET_DEVICE_CUDA)
add_compile_definitions(TARGET_DEVICE_CPU)

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} test/${PARSED_ARGS_NAME}.cpp)

  find_package(Threads REQUIRED)

  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Transpose Threads::Threads EventModel AllenZMQ Catch2::Catch2)
  if (NOT STANDALONE)
    find_package(fmt REQUIRED)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE fmt::fmt)
  endif()

  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin)
endfunction()

if (BUILD_TESTING)
  add_library(Transpose STATIC
    ${PROJECT_SOURCE_DIR}/main/src/Transpose.cpp
    ${PROJECT_SOURCE_DIR}/main/src/Provider.cpp
    ${PROJECT_SOURCE_DIR}/main/src/ZMQOutputSender.cpp)
  target_link_libraries(Transpose PUBLIC HostCommon Backend mdf LHCbEvent AllenZMQ EventModel AllenFS)

  test_program(NAME dump_banks)
  test_program(NAME test_read)
  test_program(NAME bench_read)
  test_program(NAME bench_provider )
  test_program(NAME bench_transpose)
  test_program(NAME test_mdf_transpose)

  if (NOT STANDALONE)
    test_program(NAME test_mep_banks)
    target_link_libraries(test_mep_banks PRIVATE Gaudi::GaudiKernel)
  endif()

  add_test(NAME allen_mdf_transpose COMMAND test_mdf_transpose --mdf-file root://eoslhcb.cern.ch//eos/lhcb/wg/rta/WP6/Allen/mdf_input/RetinaCluster_samples/upgrade-minbias-magdown-scifi-v5_retinacluster_mdf/upgrade-minbias-magdown-scifi-v5/mdf/upgrade-minbias-magdown-scifi-v5.mdf)
endif()
