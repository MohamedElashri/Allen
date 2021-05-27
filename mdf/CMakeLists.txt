###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Interface library for lhcb includes
add_library(LHCbEvent INTERFACE)
install(TARGETS LHCbEvent EXPORT Allen)

include_directories(${CMAKE_SOURCE_DIR}/external/Catch2/single_include/catch2)

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
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/main/include>)
target_link_libraries(mdf PUBLIC LHCbEvent)

if (NOT STANDALONE)
  target_include_directories(mdf SYSTEM PUBLIC ${Boost_INCLUDE_DIRS})
  target_link_libraries(mdf PUBLIC Boost::filesystem Boost::thread Boost::regex)
  target_link_libraries(LHCbEvent INTERFACE Gaudi::GaudiKernel LHCb::DAQEventLib)
else()
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
  target_include_directories(LHCbEvent INTERFACE lhcb)
  target_include_directories(LHCbEvent INTERFACE
    ${PROJECT_BINARY_DIR}/imported_include
    ${PROJECT_BINARY_DIR}/sequences/Gaudi/GaudiKernel/include)
  target_compile_definitions(LHCbEvent INTERFACE ODIN_WITHOUT_GAUDI)
endif()

if (ROOT_FOUND AND USE_ROOT)
  target_compile_definitions(mdf PUBLIC
    $<BUILD_INTERFACE:${ALLEN_ROOT_DEFINITIONS}>)
  target_include_directories(mdf SYSTEM PUBLIC
    $<BUILD_INTERFACE:${ROOT_INCLUDE_DIRS}>)
  target_link_libraries(mdf PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

target_link_libraries(
  mdf PRIVATE Gear Backend AllenCommon LHCbEvent)

# These tests don't need CUDA
remove_definitions(-DTARGET_DEVICE_CUDA)
add_compile_definitions(TARGET_DEVICE_CPU)

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} test/${PARSED_ARGS_NAME}.cpp)

  find_package(Threads REQUIRED)

  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Transpose Threads::Threads EventModel)
  if (NOT STANDALONE)
    find_package(fmt REQUIRED)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE fmt::fmt)
  endif()

  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin)
endfunction()

if (BUILD_TESTING)
  add_library(Transpose STATIC ${PROJECT_SOURCE_DIR}/main/src/Transpose.cpp)
  target_link_libraries(Transpose PUBLIC HostCommon Backend mdf LHCbEvent)

  test_program(NAME dump_banks)
  test_program(NAME test_read)
  test_program(NAME bench_read)
  test_program(NAME bench_provider )
  test_program(NAME bench_transpose)
  test_program(NAME test_mdf_transpose)
  if (STANDALONE)
    add_test(NAME allen_mdf_transpose COMMAND test_mdf_transpose --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  else()
    gaudi_add_test(allen_mdf_transpose COMMAND test_mdf_transpose --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  endif()
endif()
