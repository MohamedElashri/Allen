set(mdf_sources
    src/compression.cpp
    src/raw_helpers.cpp
    src/read_mdf.cpp)

if (ROOT_FOUND AND USE_ROOT)
  list(APPEND mdf_sources src/root_mdf.cpp)
endif()

allen_add_library(mdf ${mdf_sources})
target_include_directories (mdf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

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
  Common
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

  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Common mdf)
  install(TARGETS ${PARSED_ARGS_NAME} RUNTIME DESTINATION bin OPTIONAL)
endfunction()

if (BUILD_TESTS)
  test_program(NAME dump_banks)
  test_program(NAME test_read)
  test_program(NAME bench_read)
  test_program(NAME bench_provider)
  test_program(NAME bench_transpose)
  test_program(NAME test_providers)

  if (NOT GaudiProject_FOUND)
    add_test(NAME allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  else()
    gaudi_add_test(allen_providers COMMAND test_providers --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  endif()
endif()
