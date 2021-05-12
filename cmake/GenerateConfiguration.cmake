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
file(MAKE_DIRECTORY ${SEQUENCE_DEFINITION_DIR})
file(MAKE_DIRECTORY ${ALLEN_PARSER_DIR})

# We need a Python 3 interpreter
find_package(Python3 QUIET)

if (Python3_FOUND)
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
    elseif(EXISTS /cvmfs/sft.cern.ch)
      # As a last resource, try a hard-coded directory in cvmfs
      set(LIBCLANG_LIBDIR /cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib)
      set(LIBCLANG_ALTERNATIVE_FOUND ON)
    endif()
  endif()

  if (LIBCLANG_FOUND OR LIBCLANG_ALTERNATIVE_FOUND)
    # Produce algorithms.py
    add_custom_command(
      OUTPUT "${ALGORITHMS_OUTPUTFILE}"
      COMMAND
        ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/parser" "${ALLEN_PARSER_DIR}" &&
        ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/scripts/clang" "${ALLEN_PARSER_DIR}/clang" &&
        ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${LIBCLANG_LIBDIR}:$ENV{LD_LIBRARY_PATH}" "CPLUS_INCLUDE_PATH=$ENV{CPLUS_INCLUDE_PATH}" "${Python3_EXECUTABLE}" "${ALGORITHMS_GENERATION_SCRIPT}" "${ALGORITHMS_OUTPUTFILE}" "${CMAKE_SOURCE_DIR}"
      WORKING_DIRECTORY ${ALLEN_PARSER_DIR})

    if(NOT STANDALONE)
      add_custom_command(
        OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h"
        COMMAND 
          ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/AllenConf" "${SEQUENCE_DEFINITION_DIR}" &&
          ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/AllenCore" "${ALLEN_CORE_DIR}" &&
          ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
          ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "${env_cmd}" --xml "${env_xml}" "${Python3_EXECUTABLE}" "${SEQUENCE}.py" &&
          ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
          ${CMAKE_COMMAND} -E copy_if_different "ConfiguredInputAggregates.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h" &&
          ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
        DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${ALGORITHMS_OUTPUTFILE}"
        WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR})
    else()
      # Add the PyConf dependency in STANDALONE
      find_package(Git REQUIRED)
      add_custom_command(
        OUTPUT "${PROJECT_SEQUENCE_DIR}/LHCb" "${PROJECT_SEQUENCE_DIR}/PyConf" "${PROJECT_SEQUENCE_DIR}/Gaudi" "${PROJECT_SEQUENCE_DIR}/GaudiKernel"
        COMMAND
          ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone https://gitlab.cern.ch/lhcb/LHCb --no-checkout &&
          ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} -C LHCb/ checkout HEAD -- PyConf &&
          ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone https://gitlab.cern.ch/gaudi/Gaudi --no-checkout &&
          ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} -C Gaudi/ checkout HEAD -- GaudiKernel &&
          ${CMAKE_COMMAND} -E create_symlink LHCb/PyConf/python/PyConf PyConf &&
          ${CMAKE_COMMAND} -E create_symlink Gaudi/GaudiKernel/python/GaudiKernel GaudiKernel
        WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR})
      add_custom_command(
        OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h"
        COMMAND
          ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/sequences/AllenConf" "${SEQUENCE_DEFINITION_DIR}" &&
          ${CMAKE_COMMAND} -E copy_directory "${CMAKE_SOURCE_DIR}/configuration/AllenCore" "${ALLEN_CORE_DIR}" &&
          ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}" &&
          ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}" "${Python3_EXECUTABLE}" "${SEQUENCE}.py" &&
          ${CMAKE_COMMAND} -E copy_if_different "Sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
          ${CMAKE_COMMAND} -E copy_if_different "ConfiguredInputAggregates.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h" &&
          ${CMAKE_COMMAND} -E copy "Sequence.json" "${PROJECT_BINARY_DIR}/Sequence.json"
        DEPENDS "${CMAKE_SOURCE_DIR}/configuration/sequences/${SEQUENCE}.py" "${PROJECT_SEQUENCE_DIR}/PyConf" "${ALGORITHMS_OUTPUTFILE}"
        WORKING_DIRECTORY ${PROJECT_SEQUENCE_DIR})
    endif()
  else()
    message(FATAL_ERROR "No suitable libClang installation found. "
                        "You may provide a custom path to llvm-config setting LLVM_CONFIG manually")
  endif()
else()
  # Resort to pregenerated sequences
  message(STATUS "Python3 was not found. Using pregenerated sequences.")
  add_custom_command(
    OUTPUT "${PROJECT_BINARY_DIR}/Sequence.json" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_sequence.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h" &&
    ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_input_aggregates.h" "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredInputAggregates.h" &&
    ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.json" "${PROJECT_BINARY_DIR}/Sequence.json"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    DEPENDS "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_sequence.h" "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}_input_aggregates.h" "${CMAKE_SOURCE_DIR}/configuration/pregenerated/${SEQUENCE}.json"
    COMMENT "Configuring sequence ${SEQUENCE}"
    VERBATIM)
endif()

install(FILES "${PROJECT_BINARY_DIR}/Sequence.json" DESTINATION "${CMAKE_INSTALL_PREFIX}/constants")
