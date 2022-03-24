#####################################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb collaboration                 #
#                                                                                   #
# This software is distributed under the terms of the Apache version 2 licence,     #
# copied verbatim in the file "LICENSE".                                            #
#                                                                                   #
# In applying this licence, CERN does not waive the privileges and immunities       #
# granted to it by virtue of its status as an Intergovernmental Organization        #
# or submit itself to any jurisdiction.                                             #
#####################################################################################
# Module locating the umesimd Vectorisation Library headers.
#
# Defines:
#  - UMESIMD_FOUND
#  - UMESIMD_INCLUDE_DIR
#
# Imports:
#
#  umesimd::umesimd
#
# Usage of the target instead of the variables is advised

# Find quietly if already found before
if(DEFINED CACHE{UMESIMD_INCLUDE_DIR})
  set(${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY YES)
endif()

# Look for the header directory:
find_path(UMESIMD_INCLUDE_DIR
   NAMES umesimd
   HINTS $ENV{UMESIMD_ROOT_DIR} ${UMESIMD_ROOT_DIR})

# Handle the regular find_package arguments:
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(umesimd DEFAULT_MSG UMESIMD_INCLUDE_DIR)

# Mark the cached variables as "advanced":
mark_as_advanced(UMESIMD_FOUND UMESIMD_INCLUDE_DIR)

# Modernisation: create an interface target to link against
if(TARGET umesimd::umesimd)
    return()
endif()
if(UMESIMD_FOUND)
  add_library(umesimd::umesimd IMPORTED INTERFACE)
  target_include_directories(umesimd::umesimd SYSTEM INTERFACE "${UMESIMD_INCLUDE_DIR}")
  # Display the imported target for the user to know
  if(NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
    message(STATUS "  Import target: umesimd::umesimd")
  endif()
endif()
