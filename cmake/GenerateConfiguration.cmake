###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Deal with configuration generation machinery
# * If clang is available, we can and will generate the configuration files
# * Otherwise, fail and message that it is not possible to generate configurations
set(CODE_GENERATION_DIR ${CMAKE_BINARY_DIR}/code_generation)
set(PROJECT_SEQUENCE_DIR ${CODE_GENERATION_DIR}/sequences)
set(SEQUENCE_DEFINITION_DIR ${PROJECT_SEQUENCE_DIR}/AllenConf)
set(ALLEN_ALGORITHMDB_DIR ${PROJECT_SEQUENCE_DIR}/include)
set(ALLEN_CORE_DIR ${PROJECT_SEQUENCE_DIR}/AllenCore)
set(ALLEN_PARSER_DIR ${PROJECT_SEQUENCE_DIR}/parser)
set(ALGORITHMS_OUTPUTFILE ${SEQUENCE_DEFINITION_DIR}/algorithms.py)
set(PARSED_ALGORITHMS_OUTPUTFILE ${CODE_GENERATION_DIR}/parsed_algorithms.pickle)
set(ALGORITHMS_GENERATION_SCRIPT ${ALLEN_PARSER_DIR}/ParseAlgorithms.py)

include_guard(GLOBAL)

file(MAKE_DIRECTORY ${CODE_GENERATION_DIR})
file(MAKE_DIRECTORY ${ALLEN_PARSER_DIR})
file(MAKE_DIRECTORY ${ALLEN_ALGORITHMDB_DIR})

# We need a Python 3 interpreter
find_package(Python3 REQUIRED)

# Find libClang, required for parsing the Allen codebase
find_package(LibClang QUIET)

set(MINIMUM_REQUIRED_LIBCLANG_VERSION 9)
if(LIBCLANG_FOUND AND "${LIBCLANG_MAJOR_VERSION}" LESS ${MINIMUM_REQUIRED_LIBCLANG_VERSION})
  message(STATUS "libClang version found (${LIBCLANG_VERSION}) does not meet minimum version requirement (${MINIMUM_REQUIRED_LIBCLANG_VERSION})")
endif()

if(NOT LIBCLANG_FOUND OR "${LIBCLANG_MAJOR_VERSION}" LESS ${MINIMUM_REQUIRED_LIBCLANG_VERSION})
  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # In macOS, libClang typically exists even if llvm-config does not exist.
    # Attempt default directory
    set(LIBCLANG_LIBDIR /Library/Developer/CommandLineTools/usr/lib)
    set(LIBCLANG_ALTERNATIVE_FOUND ON)
    message(STATUS "Using predefined macos libclang directory")
  elseif(EXISTS /cvmfs/sft.cern.ch)
    # As a last resource, try a hard-coded directory in cvmfs
    set(LIBCLANG_LIBDIR /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib)
    set(LIBCLANG_ALTERNATIVE_FOUND ON)
    message(STATUS "Using predefined CVMFS libclang directory")
  else()
    message(FATAL_ERROR "No suitable libClang installation found. "
                        "You may provide a custom path to llvm-config by setting LLVM_CONFIG manually")
  endif()
endif()

message(STATUS "Found libclang at ${LIBCLANG_LIBDIR}")

# Parse Allen algorithms
# TODO: Parsing should depend on ALL algorithm headers and ALL algorithm sources
add_custom_command(
  OUTPUT "${PARSED_ALGORITHMS_OUTPUTFILE}"
  COMMENT "Parsing Allen algorithms"
  COMMAND
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/parser" "${ALLEN_PARSER_DIR}" &&
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/scripts/clang" "${ALLEN_PARSER_DIR}/clang" &&
    ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" --generate parsed_algorithms --filename "${PARSED_ALGORITHMS_OUTPUTFILE}" --prefix_project_folder "${CMAKE_SOURCE_DIR}"
  DEPENDS "${CMAKE_SOURCE_DIR}/configuration/parser/ParseAlgorithms.py")

# Generate algorithms.py and algorithm wrappers
add_custom_command(
  OUTPUT "${ALGORITHMS_OUTPUTFILE}"
  COMMAND
    ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" --generate views --filename "${ALGORITHMS_OUTPUTFILE}" --parsed_algorithms "${PARSED_ALGORITHMS_OUTPUTFILE}"
  WORKING_DIRECTORY ${ALLEN_PARSER_DIR}
  DEPENDS "${PARSED_ALGORITHMS_OUTPUTFILE}")

add_custom_target(generate_algorithms_view DEPENDS "${ALGORITHMS_OUTPUTFILE}")

# Symlink Allen build directories
add_custom_command(
  OUTPUT "${SEQUENCE_DEFINITION_DIR}" "${ALLEN_CORE_DIR}"
  COMMENT "Making symlink of sequence definitions and configuration utilities"
  COMMAND
    ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/configuration/python/AllenConf" "${SEQUENCE_DEFINITION_DIR}" &&
    ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/configuration/AllenCore" "${ALLEN_CORE_DIR}"
  DEPENDS "${CMAKE_SOURCE_DIR}/configuration/python/AllenConf" "${CMAKE_SOURCE_DIR}/configuration/AllenCore")

add_custom_target(generate_conf_core DEPENDS "${SEQUENCE_DEFINITION_DIR}" "${ALLEN_CORE_DIR}")

# Generate Allen AlgorithmDB
add_custom_command(
  OUTPUT "${ALLEN_ALGORITHMDB_DIR}/AlgorithmDB.h"
  COMMENT "Generating AlgorithmDB"
  COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" --generate db --filename "${ALLEN_ALGORITHMDB_DIR}/AlgorithmDB.h" --parsed_algorithms "${PARSED_ALGORITHMS_OUTPUTFILE}"
  WORKING_DIRECTORY ${ALLEN_PARSER_DIR}
  DEPENDS "${PARSED_ALGORITHMS_OUTPUTFILE}")

add_custom_target(algorithm_db DEPENDS "${ALLEN_ALGORITHMDB_DIR}/AlgorithmDB.h")


if(NOT STANDALONE)
  # We need to get the list of algorithms at configuration time in order to
  # know the list of files that will be required of this build
  set(ALGORITHM_WRAPPERS_FOLDER ${CODE_GENERATION_DIR}/algorithm_wrappers)
  set(ALGORITHM_WRAPPERS_LISTFILE ${ALGORITHM_WRAPPERS_FOLDER}/algorithm_list.txt)
  file(MAKE_DIRECTORY ${ALGORITHM_WRAPPERS_FOLDER})
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/parser" "${ALLEN_PARSER_DIR}")
  execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/scripts/clang" "${ALLEN_PARSER_DIR}/clang")
  execute_process(COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" --generate wrapperlist --filename "${ALGORITHM_WRAPPERS_LISTFILE}" --algorithm_wrappers_folder "${ALGORITHM_WRAPPERS_FOLDER}" --prefix_project_folder "${CMAKE_SOURCE_DIR}")
  file(READ "${ALGORITHM_WRAPPERS_LISTFILE}" WRAPPED_ALGORITHM_SOURCES) # WRAPPED_ALGORITHM_SOURCES="a.cpp b.cpp c.cpp"

  # Build step that will produce all .cpp conversion files
  add_custom_command(
    OUTPUT ${WRAPPED_ALGORITHM_SOURCES}
    COMMAND
      ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" --generate wrappers --parsed_algorithms "${PARSED_ALGORITHMS_OUTPUTFILE}" --algorithm_wrappers_folder "${ALGORITHM_WRAPPERS_FOLDER}"
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR}
    DEPENDS "${PARSED_ALGORITHMS_OUTPUTFILE}")
else()
  find_package(Git REQUIRED)
  add_custom_command(
    OUTPUT "${PROJECT_SEQUENCE_DIR}/LHCb" "${PROJECT_SEQUENCE_DIR}/PyConf" "${PROJECT_SEQUENCE_DIR}/Gaudi" "${PROJECT_SEQUENCE_DIR}/GaudiKernel"
    COMMENT "Checking out configuration utilities from the LHCb stack"
    COMMAND
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone https://gitlab.cern.ch/lhcb/LHCb.git --no-checkout &&
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} --work-tree=LHCb --git-dir=LHCb/.git checkout HEAD -- PyConf &&
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone https://gitlab.cern.ch/gaudi/Gaudi.git --no-checkout &&
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} --work-tree=Gaudi --git-dir=Gaudi/.git checkout HEAD -- GaudiKernel &&
      ${CMAKE_COMMAND} -E create_symlink LHCb/PyConf/python/PyConf PyConf &&
      ${CMAKE_COMMAND} -E create_symlink Gaudi/GaudiKernel/python/GaudiKernel GaudiKernel
    WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR})
  add_custom_target(checkout_gaudi_dirs DEPENDS "${PROJECT_SEQUENCE_DIR}/LHCb" "${PROJECT_SEQUENCE_DIR}/PyConf" "${PROJECT_SEQUENCE_DIR}/Gaudi" "${PROJECT_SEQUENCE_DIR}/GaudiKernel")
endif()

function(generate_sequence sequence)
  set(sequence_dir ${PROJECT_SEQUENCE_DIR}/${sequence})
  file(MAKE_DIRECTORY ${sequence_dir})

  if(NOT STANDALONE)
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/${sequence}.json"
      COMMAND
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "${env_cmd}" --xml "${env_xml}" "${CMAKE_SOURCE_DIR}/scripts/run_with_pythonpath.sh" "${PROJECT_SEQUENCE_DIR}" "${Python3_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" &&
        ${CMAKE_COMMAND} -E rename "${sequence_dir}/Sequence.json" "${PROJECT_BINARY_DIR}/${sequence}.json"
      DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" generate_algorithms_view generate_conf_core
      WORKING_DIRECTORY ${sequence_dir})
  else()
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/${sequence}.json"
      COMMAND
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "PYTHONPATH=${PROJECT_SEQUENCE_DIR}:$ENV{PYTHONPATH}" "${Python3_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" &&
        ${CMAKE_COMMAND} -E rename "${sequence_dir}/Sequence.json" "${PROJECT_BINARY_DIR}/${sequence}.json"
      DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" generate_algorithms_view generate_conf_core checkout_gaudi_dirs
      WORKING_DIRECTORY ${sequence_dir})
  endif()
  add_custom_target(sequence_${sequence} DEPENDS "${PROJECT_BINARY_DIR}/${sequence}.json")

  install(FILES "${PROJECT_BINARY_DIR}/${sequence}.json" DESTINATION "${CMAKE_INSTALL_PREFIX}/constants")
endfunction()
