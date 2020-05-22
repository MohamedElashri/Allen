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
set(CLANG10_LD_LIBRARY_PATH /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib64)
set(REQUIRED_CPLUS_PATH /cvmfs/sft.cern.ch/lcg/views/LCG_97python3/x86_64-centos7-gcc8-opt/include)
set(DEFAULT_MOORE_RUN "/scratch/dcampora/gaudi_projects/MooreDev_v51r0/run")

message(STATUS "Generating sequence using LLVM")

if(MOORE_INSTALL_DIR STREQUAL "")
  set(MOORE_RUN ${DEFAULT_MOORE_RUN})
else()
  set(MOORE_RUN ${MOORE_INSTALL_DIR}/run)
endif()

# From CMake on execute_process:
# "If a sequential execution of multiple commands is required, use multiple execute_process() calls with a single COMMAND argument."
if(${MOORE_GENERATOR})
  message(STATUS "Testing code generation with LLVM - Configured generator: Moore")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/gaudi/definitions" "${SEQUENCE_DEFINITION_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/gaudi/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1)
  execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Moore"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_2)
  execute_process(COMMAND ${MOORE_RUN} ${SEQUENCE_DEFINITION_DIR}/allenrun.py ${SEQUENCE}.py
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_3)
else()
  message(STATUS "Testing code generation with LLVM - Configured generator: Allen")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_0)
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_1)
  execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_2)
  execute_process(COMMAND python3 ${SEQUENCE}.py
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    RESULT_VARIABLE ALGORITHMS_GENERATION_RESULT_3)
endif()

if(Python3_FOUND AND ${ALGORITHMS_GENERATION_RESULT_0} EQUAL 0 AND ${ALGORITHMS_GENERATION_RESULT_1} EQUAL 0 AND
  ${ALGORITHMS_GENERATION_RESULT_2} EQUAL 0 AND ${ALGORITHMS_GENERATION_RESULT_3} EQUAL 0)
  message(STATUS "Testing code generation with LLVM - Success")
  if(${MOORE_GENERATOR})
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/gaudi/definitions" "${SEQUENCE_DEFINITION_DIR}" &&
        ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/gaudi/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Moore" &&
        ${MOORE_RUN} ${SEQUENCE_DEFINITION_DIR}/allenrun.py ${SEQUENCE}.py &&
        ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
        ${CMAKE_COMMAND} -E copy_if_different "ConfiguredLines.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredLines.h" &&
        ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
      DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py"
      WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    )
  else()
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/definitions" "${SEQUENCE_DEFINITION_DIR}" &&
        ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${CLANG10_LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=${REQUIRED_CPLUS_PATH}" python3 ${ALGORITHMS_GENERATION_SCRIPT} ${ALGORITHMS_OUTPUTFILE} ${CMAKE_SOURCE_DIR} "Allen" &&
        python3 ${SEQUENCE}.py &&
        ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
        ${CMAKE_COMMAND} -E copy_if_different "ConfiguredLines.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredLines.h" &&
        ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
      DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py"
      WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    )
  endif()
else()
  if (Python3_FOUND)
    message(WARNING "Sequence generation with LLVM - Failed. CVMFS (sft.cern.ch) or clang >= 9.0.0 are required to be able to generate configurations.")
    message(WARNING "A pregenerated sequence will be used instead.")
  else()
    message(WARNING "Failed to generate sequence. Please note Python 3 AND (CVMFS (sft.cern.ch) OR clang >= 9.0.0) are required to be able to generate configurations.")
  endif()

  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
    ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_lines.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredLines.h" &&
    ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.json" "${PROJECT_BINARY_DIR}/Sequence.json"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.h"
    COMMENT "Configuring sequence ${SEQUENCE}"
    VERBATIM
  )
endif()

install(FILES "${PROJECT_BINARY_DIR}/Sequence.json" DESTINATION "${CMAKE_INSTALL_PREFIX}/constants")
