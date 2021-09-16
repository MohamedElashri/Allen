###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Deal with configuration generation machinery
# * If clang is available, we can and will generate the configuration files
# * Otherwise, fail and message that it is not possible to generate configurations
set(PROJECT_SEQUENCE_DIR ${CMAKE_BINARY_DIR}/sequences)
set(SEQUENCE_DEFINITION_DIR ${PROJECT_SEQUENCE_DIR}/AllenConf)
set(ALLEN_CORE_DIR ${PROJECT_SEQUENCE_DIR}/AllenCore)
set(ALLEN_PARSER_DIR ${PROJECT_SEQUENCE_DIR}/parser)
set(ALGORITHMS_OUTPUTFILE ${SEQUENCE_DEFINITION_DIR}/algorithms.py)
set(ALGORITHMS_GENERATION_SCRIPT ${ALLEN_PARSER_DIR}/ParseAlgorithms.py)
file(MAKE_DIRECTORY ${ALLEN_PARSER_DIR})

# We need a Python 3 interpreter
find_package(Python3 REQUIRED)

# Find libClang, required for parsing the Allen codebase
find_package(LibClang QUIET)

set(MINIMUM_REQUIRED_LIBCLANG_VERSION 9)
if(${LIBCLANG_FOUND} AND "${LIBCLANG_MAJOR_VERSION}" GREATER_EQUAL ${MINIMUM_REQUIRED_LIBCLANG_VERSION})
  set(LIBCLANG_MINIMUM_VERSION_FOUND TRUE)
else()
  set(LIBCLANG_MINIMUM_VERSION_FOUND FALSE)
endif()

if(NOT LIBCLANG_MINIMUM_VERSION_FOUND)
  if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    # In macOS, libClang typically exists even if llvm-config does not exist.
    # Attempt default directory
    set(LIBCLANG_LIBDIR /Library/Developer/CommandLineTools/usr/lib)
  elseif(EXISTS /cvmfs/sft.cern.ch)
    # As a last resource, try a hard-coded directory in cvmfs
    set(LIBCLANG_LIBDIR /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib)
  else()
    message(FATAL_ERROR "No suitable libClang installation found. "
                        "You may provide a custom path to llvm-config by setting LLVM_CONFIG manually")
  endif()
endif()

message(STATUS "Found libclang at ${LIBCLANG_LIBDIR}")

# Copy directories only once
add_custom_command(
  OUTPUT "${SEQUENCE_DEFINITION_DIR}" "${ALLEN_CORE_DIR}"
  COMMENT "Copying sequence definitions and configuration utilities"
  COMMAND
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/AllenConf" "${SEQUENCE_DEFINITION_DIR}" &&
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/AllenCore" "${ALLEN_CORE_DIR}")

add_custom_target(copy_dirs DEPENDS "${SEQUENCE_DEFINITION_DIR}" "${ALLEN_CORE_DIR}")

# Produce algorithms.py
add_custom_command(
  OUTPUT "${ALGORITHMS_OUTPUTFILE}"
  COMMAND
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/parser" "${ALLEN_PARSER_DIR}" &&
    ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/scripts/clang" "${ALLEN_PARSER_DIR}/clang" &&
    ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" "${ALGORITHMS_OUTPUTFILE}" "${CMAKE_SOURCE_DIR}"
  WORKING_DIRECTORY ${ALLEN_PARSER_DIR})

add_custom_target(gen_algorithms DEPENDS copy_dirs "${ALGORITHMS_OUTPUTFILE}")

if (STANDALONE)
  # Add the PyConf dependency in STANDALONE
  find_package(Git REQUIRED)
  add_custom_command(
    OUTPUT "${PROJECT_SEQUENCE_DIR}/LHCb" "${PROJECT_SEQUENCE_DIR}/PyConf" "${PROJECT_SEQUENCE_DIR}/Gaudi" "${PROJECT_SEQUENCE_DIR}/GaudiKernel"
    COMMENT "Checking-out configuration utilities from the LHCb stack"
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
  set(generate_dir ${PROJECT_SEQUENCE_DIR}/generate_${sequence})
  file(MAKE_DIRECTORY ${sequence_dir})
  file(MAKE_DIRECTORY ${generate_dir})
  if(NOT STANDALONE)
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/${sequence}.json" "${sequence_dir}/ConfiguredSequence.h"
      COMMAND
        ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" "${generate_dir}" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "${env_cmd}" --xml "${env_xml}" -a PYTHONPATH=${PROJECT_SEQUENCE_DIR} "${Python3_EXECUTABLE}" "${sequence}.py" &&
        ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${sequence_dir}/ConfiguredSequence.h" &&
        ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/${sequence}.json"
      DEPENDS gen_algorithms
      COMMENT "Generating headers and configuration: ${sequence}."
      WORKING_DIRECTORY ${generate_dir})
  else()
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/${sequence}.json" "${sequence_dir}/ConfiguredSequence.h"
      COMMAND
        ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${sequence}.py" "${generate_dir}" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "PYTHONPATH=$ENV{PYTHONPATH}:${PROJECT_SEQUENCE_DIR}" "${Python3_EXECUTABLE}" "${sequence}.py" &&
        ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${sequence_dir}/ConfiguredSequence.h" &&
        ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/${sequence}.json"
      DEPENDS gen_algorithms checkout_gaudi_dirs
      COMMENT "Generating headers and configuration: ${sequence}."
      WORKING_DIRECTORY ${generate_dir})
  endif()

  install(FILES "${PROJECT_BINARY_DIR}/${sequence}.json" DESTINATION "${CMAKE_INSTALL_PREFIX}/constants")
endfunction()
