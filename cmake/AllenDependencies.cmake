###############################################################################
# (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
if (NOT STANDALONE)
  message(STATUS "LHCb stack build")

  # Find modules we need
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/modules)

  if(NOT COMMAND lhcb_find_package)
    # Look for LHCb find_package wrapper
    find_file(LHCbFindPackage_FILE LHCbFindPackage.cmake)
    if(LHCbFindPackage_FILE)
        include(${LHCbFindPackage_FILE})
    else()
        # if not found, use the standard find_package
        macro(lhcb_find_package)
            find_package(${ARGV})
        endmacro()
    endif()
  endif()

  # -- Public dependencies
  lhcb_find_package(Rec 32.0 REQUIRED)

  find_package(AIDA REQUIRED)
  find_package(fmt REQUIRED)

  #Always enable ROOT for LHCb stack builds
  set(USE_ROOT ON)
endif()

find_package(cppgsl REQUIRED)

if(STANDALONE OR WITH_Allen_PRIVATE_DEPENDENCIES)
  # https://github.com/nlohmann/json
  find_package(nlohmann_json REQUIRED)

  # Boost
  find_package(Boost REQUIRED COMPONENTS filesystem iostreams thread regex
    serialization program_options)

  find_package(PkgConfig)
  pkg_check_modules(zmq libzmq REQUIRED IMPORTED_TARGET)  # for ZeroMQ

  # std::filesytem detection
  find_package(Filesystem)
endif()

# ROOT
if (STANDALONE AND USE_ROOT)
  if(EXISTS $ENV{ROOTSYS}/cmake/ROOTConfig.cmake) # ROOT was compiled with cmake
    set(ALLEN_ROOT_CMAKE $ENV{ROOTSYS})
  elseif(EXISTS $ENV{ROOTSYS}/ROOTConfig.cmake)
    set(ALLEN_ROOT_CMAKE $ENV{ROOTSYS})
  elseif($ENV{ROOTSYS}) # ROOT was compiled with configure/make
    set(ALLEN_ROOT_CMAKE $ENV{ROOTSYS}/etc)
  else()
    message(FATAL "ROOTSYS must be set to use ROOT with a standalone build of Allen")
  endif()
  find_package(ROOT QUIET HINTS ${ALLEN_ROOT_CMAKE} NO_DEFAULT_PATH COMPONENTS Core Hist Tree)
  if (ROOT_FOUND)
    message(STATUS "Compiling with ROOT: " ${ROOT_INCLUDE_DIRS})

    #If ROOT is built with C++ 17 support, everything that includes ROOT
    #headers must be built with C++ 17 support.CUDA doesn't support
    #that, so we have to factor that out.
    execute_process(COMMAND root-config --has-cxx17 OUTPUT_VARIABLE ROOT_HAS_CXX17 ERROR_QUIET)
    string(REGEX REPLACE "\n$" "" ROOT_HAS_CXX17 "${ROOT_HAS_CXX17}")
    message(STATUS "ROOT built with c++17: ${ROOT_HAS_CXX17}")
    if ("${ROOT_HAS_CXX17}" STREQUAL "yes")
      set(ALLEN_ROOT_DEFINITIONS WITH_ROOT ROOT_CXX17)
    else()
      set(ALLEN_ROOT_DEFINITIONS WITH_ROOT)
    endif()

    set(ALLEN_ROOT_LIBRARIES -L$ENV{ROOTSYS}/lib -lCore -lCling -lHist -lTree -lRIO)

    execute_process(COMMAND root-config --has-imt OUTPUT_VARIABLE ROOT_HAS_IMT ERROR_QUIET)
    string(REGEX REPLACE "\n$" "" ROOT_HAS_IMT "${ROOT_HAS_IMT}")
    message(STATUS "ROOT built with implicit multi-threading: ${ROOT_HAS_IMT}")
    if (${ROOT_HAS_IMT} STREQUAL "yes")
      find_package(TBB REQUIRED)
      get_filename_component(TBB_LIBDIR ${TBB_LIBRARIES} DIRECTORY)
      set(ALLEN_ROOT_LIBRARIES ${ALLEN_ROOT_LIBRARIES} -L${TBB_LIBDIR} -ltbb)
    endif()
  else()
    message(STATUS "Compiling without ROOT")
  endif()
elseif(WITH_Allen_PRIVATE_DEPENDENCIES)
  find_package(ROOT REQUIRED COMPONENTS Core Hist Tree RIO Thread)
  find_package(TBB REQUIRED)
  set(ALLEN_ROOT_DEFINITIONS WITH_ROOT ROOT_CXX17)
  set(ALLEN_ROOT_LIBRARIES ${ROOT_LIBRARIES} ${TBB_LIBRARIES})
elseif(STANDALONE)
   message(STATUS "Compiling without ROOT")
endif()
