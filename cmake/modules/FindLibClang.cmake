###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

# This module looks for libClang, and uses the llvm-config utility to find out
# information about the libClang installation.
#
# It defines the following variables:
#
# * LIBCLANG_FOUND - whether the library was found
# * LIBCLANG_LIBDIR - directory where libClang is
# * LIBCLANG_VERSION - version of libClang
# * LIBCLANG_MAJOR_VERSION - major version

include(FindPackageHandleStandardArgs)

if (NOT LLVM_CONFIG AND STANDALONE)
    set(LLVM_CONFIG $ENV{LLVM_CONFIG})
    if (NOT LLVM_CONFIG)
        find_program(LLVM_CONFIG "llvm-config")
    endif ()
    if (NOT LLVM_CONFIG)
        set(llvm_config_names llvm-config)
        foreach(major RANGE 11 3)
            list(APPEND llvm_config_names "llvm-config${major}" "llvm-config-${major}")
            foreach(minor RANGE 9 0)
                list(APPEND llvm_config_names "llvm-config${major}${minor}" "llvm-config-${major}.${minor}" "llvm-config-mp-${major}.${minor}")
            endforeach ()
        endforeach ()
        find_program(LLVM_CONFIG NAMES ${llvm_config_names})
    endif ()
endif ()

if (NOT LLVM_CONFIG)
    if (NOT LibClang_FIND_QUIETLY)
        message(FATAL_ERROR "Could not find llvm-config. Please set LLVM_CONFIG manually.")
    endif ()
else ()
    # Obtain libdir
    execute_process(COMMAND ${LLVM_CONFIG} --libdir OUTPUT_VARIABLE LIBCLANG_LIBDIR OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (NOT EXISTS ${LIBCLANG_LIBDIR})
        message(FATAL_ERROR "Could not find libClang libdir. Please set LIBCLANG_LIBDIR manually.")
    endif ()
    set(LIBCLANG_LIBDIR ${LIBCLANG_LIBDIR} CACHE STRING "Path to libClang.")

    # Obtain full version
    execute_process(COMMAND ${LLVM_CONFIG} --version OUTPUT_VARIABLE LIBCLANG_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(LIBCLANG_VERSION ${LIBCLANG_VERSION} CACHE STRING "Version of libClang.")

    # Obtain major version
    string(REPLACE "." ";" LIBCLANG_VERSION_LIST ${LIBCLANG_VERSION})
    list(GET LIBCLANG_VERSION_LIST 0 LIBCLANG_MAJOR_VERSION)
    set(LIBCLANG_MAJOR_VERSION ${LIBCLANG_MAJOR_VERSION} CACHE STRING "Major version of libClang.")

    # Notify libClang
    message(STATUS "Found libClang: ${LIBCLANG_LIBDIR} (found version ${LIBCLANG_VERSION})")
endif ()

find_package_handle_standard_args(LibClang DEFAULT_MSG LIBCLANG_LIBDIR LIBCLANG_VERSION LIBCLANG_MAJOR_VERSION)
mark_as_advanced(LIBCLANG_LIBDIR LIBCLANG_VERSION LIBCLANG_MAJOR_VERSION)
