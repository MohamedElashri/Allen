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

# We need Python 3
find_package (Python3 COMPONENTS Interpreter QUIET)

# We need to pass a custom LD_LIBRARY_PATH to point to a compatible clang version
# TODO: Figure out if there is a cleaner way to do this
set(CLANG10_LD_LIBRARY_PATH /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib64:/Library/Developer/CommandLineTools/usr/lib)
set(REQUIRED_CPLUS_PATH /cvmfs/sft.cern.ch/lcg/views/LCG_97python3/x86_64-centos7-gcc8-opt/include)

message(STATUS "Generating sequence using LLVM")

# From CMake on execute_process:
# "If a sequential execution of multiple commands is required, use multiple execute_process() calls with a single COMMAND argument."
message(STATUS "Testing code generation with LLVM - Configured generator: Allen")

if (SEQUENCE_GENERATION AND Python3_FOUND)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1)
  execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}" ${Python3_EXECUTABLE} ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen"
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
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}:${CPLUS_INCLUDE_PATH}" ${Python3_EXECUTABLE} ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen" &&
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
  if(SEQUENCE_GENERATION AND Python3_FOUND)
    message(STATUS "Testing code generation with LLVM - Failed. Please note that cvmfs (sft.cern.ch) or clang >= 9.0.0 are required to be able to generate configurations.")
    message(STATUS "A pregenerated sequence will be used instead.")
  elseif(SEQUENCE_GENERATION)
    message(STATUS "Testing code generation with LLVM - Failed. Please note that Python 3 is required to be able to generate configurations.")
  else()
    message(STATUS "Testing code generation with LLVM - Disabled")
  endif()

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
