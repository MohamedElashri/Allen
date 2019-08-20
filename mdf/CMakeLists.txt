set(SOURCES
  src/compression.cpp
  src/raw_helpers.cpp
  src/read_mdf.cpp)

add_library(mdf ${SOURCES})
target_include_directories (mdf PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

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

function(test_program)
  cmake_parse_arguments(PARSED_ARGS "NO_CUDA" "NAME" "" ${ARGN})
  add_executable(${PARSED_ARGS_NAME} test/${PARSED_ARGS_NAME}.cpp)

  target_include_directories(${PARSED_ARGS_NAME} PUBLIC
    ${CMAKE_SOURCE_DIR}/mdf/include
    ${CMAKE_SOURCE_DIR}/main/include)

  if (NOT ${PARSED_ARGS_NO_CUDA})
    target_include_directories(${PARSED_ARGS_NAME} PUBLIC
      ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
      ${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include
      ${CMAKE_SOURCE_DIR}/cuda/event_model/common/include
      ${CMAKE_SOURCE_DIR}/cuda/velo/common/include
      ${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include
      ${CMAKE_SOURCE_DIR}/cuda/muon/common/include
      ${CMAKE_SOURCE_DIR}/cuda/UT/common/include
      ${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include
      ${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include
      ${CMAKE_SOURCE_DIR}/cuda/PV/common/include
      ${CMAKE_SOURCE_DIR}/checker/tracking/include)

    set_property(TARGET ${PARSED_ARGS_NAME} PROPERTY
      CUDA_SEPARABLE_COMPILATION ON)
    target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Velo)
  else()
    target_compile_definitions(${PARSED_ARGS_NAME} PRIVATE NO_CUDA)
  endif()
  target_link_libraries(${PARSED_ARGS_NAME} PRIVATE Common mdf)
endfunction()

if(NOT CPU)
  test_program(NAME dump_banks)

  if (BUILD_TESTS)
    include(Catch)

    test_program(NAME test_read)
    test_program(NAME test_read_bin)
    test_program(NAME bench_read NO_CUDA)
    test_program(NAME bench_provider NO_CUDA)
    test_program(NAME bench_transpose NO_CUDA)

    test_program(NAME test_providers)
    catch_discover_tests(test_providers EXTRA_ARGS --directory ${CMAKE_SOURCE_DIR}/input/minbias)
  endif()
endif()
