###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
find_package(Boost REQUIRED COMPONENTS iostreams)

include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${Boost_INCLUDE_DIRS})
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/external/Catch2/single_include/catch2)

set(mdf_sources
    src/raw_helpers.cpp
    src/read_mdf.cpp
    src/read_mep.cpp
    src/write_mdf.cpp)

if (ROOT_FOUND AND USE_ROOT)
  list(APPEND mdf_sources src/root_mdf.cpp)
endif()

allen_add_host_library(mdf STATIC ${mdf_sources})
target_include_directories (mdf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
if (STANDALONE)
  # Make sure we have a local copy of ODIN.h if building in standalone mode
  set(odin_files "src/ODIN.cpp" "include/Event/ODIN.h")
  foreach(odin_file ${odin_files})
    if (NOT EXISTS "${PROJECT_BINARY_DIR}/imported_${odin_file}")
      file(DOWNLOAD "https://gitlab.cern.ch/lhcb/LHCb/-/raw/529de2de27556999faf632d491b18af0178afc98/Event/DAQEvent/${odin_file}"
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
  target_include_directories(mdf PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/lhcb
    ${PROJECT_BINARY_DIR}/sequences/Gaudi/GaudiKernel/include
    ${PROJECT_BINARY_DIR}/imported_include)
  target_compile_definitions(mdf PUBLIC ODIN_WITHOUT_GAUDI)
else()
  find_package(Boost COMPONENTS filesystem thread regex)
  target_include_directories(mdf SYSTEM PUBLIC ${Boost_INCLUDE_DIRS})
  target_link_libraries(mdf PUBLIC Boost::filesystem Boost::thread Boost::regex Gaudi::GaudiKernel LHCb::DAQEventLib)
endif()

if (ROOT_FOUND AND USE_ROOT)
  target_compile_definitions(mdf PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(mdf SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  target_link_libraries(mdf PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

target_include_directories(
  mdf PUBLIC
  ${CMAKE_SOURCE_DIR}/main/include)

target_link_libraries(
  mdf PUBLIC)

# These tests don't need CUDA
remove_definitions(-DTARGET_DEVICE_CUDA)
add_compile_definitions(TARGET_DEVICE_CPU)

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} test/${PARSED_ARGS_NAME}.cpp)

  find_package(Threads REQUIRED)

  target_include_directories(${PARSED_ARGS_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/mdf/include
    ${CMAKE_SOURCE_DIR}/main/include)

  if (STANDALONE)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE MdfTestCommon Threads::Threads)
  else()
    find_package(fmt REQUIRED)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE MdfTestCommon Threads::Threads fmt::fmt)
  endif()

  if (USE_MPI AND MPI_FOUND)
    target_compile_definitions(${PARSED_ARGS_NAME} PRIVATE HAVE_MPI)
    target_include_directories(${PARSED_ARGS_NAME} PRIVATE SYSTEM ${MPI_CXX_INCLUDE_PATH})
    get_filename_component(MPI_LIBRARY_DIR ${MPI_mpi_LIBRARY} DIRECTORY)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE ${MPI_CXX_LIBRARIES})
    if (HWLOC_FOUND)
      target_link_libraries(AllenLib PUBLIC -L${MPI_LIBRARY_DIR} PkgConfig::HWLOC open-pal)
      target_compile_definitions(AllenLib PRIVATE HAVE_HWLOC)
    endif()
  endif()

  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin OPTIONAL)
endfunction()

# Build our own common library to avoid circular dependency in Gaudi build
foreach(common_src BankTypes.cpp Timer.cpp Logger.cpp Transpose.cpp TransposeMEP.cpp InputTools.cpp)
  list(APPEND common_sources ${CMAKE_SOURCE_DIR}/main/src/${common_src})
endforeach()
allen_add_host_library(MdfTestCommon STATIC ${common_sources} ${CMAKE_SOURCE_DIR}/backend/src/CPUBackend.cpp)
target_link_libraries(MdfTestCommon PUBLIC mdf allen_fs)

test_program(NAME mdf_to_mep)

if (BUILD_TESTS)
  test_program(NAME dump_banks)
  test_program(NAME test_read)
  test_program(NAME bench_read)
  test_program(NAME bench_provider )
  test_program(NAME bench_transpose)
  test_program(NAME test_providers)
  test_program(NAME test_mdf_transpose)
  test_program(NAME test_mep_banks)
  if (STANDALONE)
    add_test(NAME allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias/)
    add_test(NAME allen_mdf_transpose COMMAND test_mdf_transpose --directory ${CMAKE_SOURCE_DIR}/input/minbias/)
  else()
    gaudi_add_test(allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias/)
    gaudi_add_test(allen_mdf_transpose COMMAND test_mdf_transpose --directory ${CMAKE_SOURCE_DIR}/input/minbias/)
  endif()
endif()
