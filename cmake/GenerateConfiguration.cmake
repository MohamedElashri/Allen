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
find_package (Python3 COMPONENTS Interpreter Development REQUIRED)

# We need to pass a custom LD_LIBRARY_PATH to point to a compatible clang version
# TODO: Figure out if there is a cleaner way to do this
set(CLANG10_LD_LIBRARY_PATH /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib64)

message(STATUS "Testing code generation with LLVM")

# From CMake on execute_process:
# "If a sequential execution of multiple commands is required, use multiple execute_process() calls with a single COMMAND argument."
execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}"
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0)
execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}"
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1)
execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR}
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_2)
execute_process(COMMAND python3 ${SEQUENCE}.py
  WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_3)

if(${ALGORITHMS_GENERATION_RESULT_0} EQUAL 1 OR ${ALGORITHMS_GENERATION_RESULT_1} EQUAL 1 OR
  ${ALGORITHMS_GENERATION_RESULT_2} EQUAL 1 OR ${ALGORITHMS_GENERATION_RESULT_3} EQUAL 1)
  message(WARNING "Testing code generation with LLVM - Failed. CVMFS (sft.cern.ch) or clang >= 9.0.0 are required to be able to generate configurations.")
  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
    ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.json" "${PROJECT_BINARY_DIR}/Sequence.json"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.h"
    COMMENT "Configuring sequence ${SEQUENCE}"
    VERBATIM
  )
else()
  message(STATUS "Testing code generation with LLVM - Success")
  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}" &&
      ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
      ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} &&
      python3 ${SEQUENCE}.py &&
      ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
      ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
  )
endif()
