set(mdf_sources
    src/compression.cpp
    src/raw_helpers.cpp
    src/read_mdf.cpp
    src/read_mep.cpp
    src/write_mdf.cpp)

if (ROOT_FOUND AND USE_ROOT)
  list(APPEND mdf_sources src/root_mdf.cpp)
endif()

allen_add_library(mdf ${mdf_sources})
target_include_directories (mdf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
if (NOT GaudiProject_FOUND)
  target_include_directories (mdf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/lhcb)
else()
  find_package(Boost COMPONENTS filesystem thread regex)
  target_link_libraries(mdf PUBLIC GaudiKernel Boost::filesystem Boost::thread Boost::regex)
  target_include_directories(mdf SYSTEM PUBLIC ${Boost_INCLUDE_DIRS})
endif()

if (ROOT_FOUND AND USE_ROOT)
  target_compile_definitions(mdf PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(mdf SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  target_link_libraries(mdf PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

target_include_directories(
  mdf PUBLIC
  ${CMAKE_SOURCE_DIR}/main/include
  ${ZLIB_INCLUDE_DIRS})

target_link_libraries(
  mdf PUBLIC
  ${ZLIB_LIBRARIES})

if (LZMA_FOUND)
  target_include_directories(
	mdf PUBLIC
	${LIBLZMA_INCLUDE_DIRS})

  target_link_libraries(
	mdf PUBLIC
	${LIBLZMA_LIBRARIES})

  target_compile_definitions(
	mdf	PRIVATE
	"-DHAVE_LZMA")
endif (LZMA_FOUND)

if (LZ4_FOUND)
  target_include_directories(
	mdf PUBLIC
	${LIBLZ4_INCLUDE_DIRS})

  target_link_libraries(
	mdf
	${LIBLZ4_LIBRARIES})

  target_compile_definitions(
	mdf	PRIVATE
	"-DHAVE_LZ4")
endif (LZ4_FOUND)

# These tests don't need CUDA
add_compile_definitions(NO_CUDA)

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "" "NAME" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} test/${PARSED_ARGS_NAME}.cpp)

  target_include_directories(${PARSED_ARGS_NAME} PUBLIC
    ${CMAKE_SOURCE_DIR}/mdf/include
    ${CMAKE_SOURCE_DIR}/main/include)

  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE MdfTestCommon)

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
foreach(common_src BankTypes.cpp Timer.cpp Logger.cpp TransposeMEP.cpp InputTools.cpp)
  list(APPEND common_sources ${CMAKE_SOURCE_DIR}/main/src/${common_src})
endforeach()
allen_add_library(MdfTestCommon STATIC ${common_sources})
target_link_libraries(MdfTestCommon PUBLIC mdf allen_fs)

test_program(NAME mdf_to_mep)

if (BUILD_TESTS)
  test_program(NAME dump_banks)
  test_program(NAME test_read)
  test_program(NAME bench_read)
  test_program(NAME bench_provider )
  test_program(NAME bench_transpose)
  test_program(NAME test_providers)
  if (NOT GaudiProject_FOUND)
    add_test(NAME allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  else()
    gaudi_add_test(allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  endif()
endif()
