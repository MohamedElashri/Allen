###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
# Deal with configuration generation machinery
# Test by actually trying to generate "algorithms.py"
# * If clang is available, we can and will generate the configuration files
# * Otherwise, warn that it is not possible to generate configurations
set(PROJECT_SEQUENCE_DIR ${CMAKE_BINARY_DIR}/sequences)
set(SEQUENCE_DEFINITION_DIR ${PROJECT_SEQUENCE_DIR}/definitions)
set(ALGORITHMS_OUTPUTFILE ${SEQUENCE_DEFINITION_DIR}/algorithms.py)
set(ALGORITHMS_GENERATION_SCRIPT ${CMAKE_SOURCE_DIR}/scripts/ParseAlgorithms.py)
file(MAKE_DIRECTORY ${SEQUENCE_DEFINITION_DIR})

# We need a Python 3 interpreter
find_package (Python3 COMPONENTS Interpreter QUIET)

# Find libClang, required for parsing the Allen codebase
set(MINIMUM_REQUIRED_LIBCLANG_VERSION 9)

find_package(LibClang QUIET)
if(LIBCLANG_FOUND AND "${LIBCLANG_MAJOR_VERSION}" LESS ${MINIMUM_REQUIRED_LIBCLANG_VERSION})
  message(STATUS "libClang version found (${LIBCLANG_VERSION}) does not meet minimum version requirement (${MINIMUM_REQUIRED_LIBCLANG_VERSION})")
endif()

if(NOT LIBCLANG_FOUND OR "${LIBCLANG_MAJOR_VERSION}" LESS ${MINIMUM_REQUIRED_LIBCLANG_VERSION})
  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # In macOS, libClang typically exists even if llvm was not installed.
    # Attempt default directory
    set(LIBCLANG_LIBDIR /Library/Developer/CommandLineTools/usr/lib)
  elseif(EXISTS /cvmfs/sft.cern.ch)
    # As a last resource, try a hard-coded directory in cvmfs
    set(LIBCLANG_LIBDIR /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib)
  endif()
endif()

message(STATUS "Testing code generation with LLVM")

# From CMake on execute_process:
# "If a sequential execution of multiple commands is required, use multiple execute_process() calls with a single COMMAND argument."
if (SEQUENCE_GENERATION AND Python3_FOUND)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1)
  execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" ${Python3_EXECUTABLE} ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_2)
  execute_process(COMMAND ${Python3_EXECUTABLE} ${SEQUENCE}.py
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_3)

  if(${ALGORITHMS_GENERATION_RESULT_0} EQUAL 0 AND ${ALGORITHMS_GENERATION_RESULT_1} EQUAL 0 AND
    ${ALGORITHMS_GENERATION_RESULT_2} EQUAL 0 AND ${ALGORITHMS_GENERATION_RESULT_3} EQUAL 0)
    message(STATUS "Testing code generation with LLVM - Success")
    set(SEQUENCE_GENERATION_SUCCESS TRUE)
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}" &&
        ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" ${Python3_EXECUTABLE} ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen" &&
        ${Python3_EXECUTABLE} ${SEQUENCE}.py &&
        ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
        ${CMAKE_COMMAND} -E copy_if_different "ConfiguredInputAggregates.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h" &&
        ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
      DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py"
      WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    )
  endif()
endif()

if(NOT SEQUENCE_GENERATION_SUCCESS)
  if(SEQUENCE_GENERATION)
    if(NOT Python3_FOUND)
      message(STATUS "Testing code generation with LLVM - Failed. No Python3 interpreter was found.")
    elseif(NOT LIBCLANG_FOUND)
      message(STATUS "Testing code generation with LLVM - Failed. No suitable libClang installation found.")
    else()
      message(STATUS "Testing code generation with LLVM - Failed.")
    endif()
  else()
    message(STATUS "Testing code generation with LLVM - Disabled")
  endif()
  message(STATUS "A pregenerated sequence will be used instead.")

  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
    ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_input_aggregates.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h" &&
    ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.json" "${PROJECT_BINARY_DIR}/Sequence.json"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_sequence.h"
    COMMENT "Configuring sequence ${SEQUENCE}"
    VERBATIM
  )
endif()

install(FILES "${PROJECT_BINARY_DIR}/Sequence.json" DESTINATION "${CMAKE_INSTALL_PREFIX}/constants")
