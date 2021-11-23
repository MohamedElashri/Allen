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

  # Detect device target from binary tag
  set(target_hip FALSE)
  set(target_cuda FALSE)

  string(REPLACE "+" ";" compiler_split "${LCG_COMPILER}")
  foreach(device_comp IN LISTS compiler_split)
    # "${device_comp}" MATCHES "cuda([0-9]+)_([0-9]+)((gcc|clang)([0-9]+))?" OR
    if (DEFINED CMAKE_CUDA_COMPILER)
      set(target_cuda TRUE)
    elseif ("${device_comp}" STREQUAL "hip")
      set(target_hip TRUE)
    endif()
  endforeach()

  if(${target_hip} AND NOT ${target_cuda})
    set(device "HIP")
  elseif(${target_cuda} AND NOT ${target_hip})
    set(device "CUDA")
  elseif(${target_cuda} AND ${target_hip})
  	message(FATAL_ERROR "Cannot simultaneously build for HIP and CUDA targets")
  else()
	set(device "CPU")
  endif()

  set(TARGET_DEVICE ${device} CACHE STRING "Target architecture of the device")
endif()

message(STATUS "Allen device target: " ${TARGET_DEVICE})

# Device runtime libraries
if(TARGET_DEVICE STREQUAL "CUDA")
  if (DEFINED CMAKE_CUDA_COMPILER)
    get_filename_component(nvcc_bin ${CMAKE_CUDA_COMPILER} DIRECTORY)
    get_filename_component(cuda_root ${nvcc_bin} DIRECTORY)
    set(CUDAToolkit_ROOT ${cuda_root})
  endif()
  find_package(CUDAToolkit REQUIRED)
elseif(TARGET_DEVICE STREQUAL "HIP")
  # Setup HIPCC compiler
  if(NOT DEFINED ROCM_PATH)
    if(NOT DEFINED ENV{ROCM_PATH})
      set(ROCM_PATH "/opt/rocm" CACHE PATH "Path where ROCM has been installed")
    else()
      set(ROCM_PATH $ENV{ROCM_PATH} CACHE PATH "Path where ROCM has been installed")
    endif()
  endif()

  set(HIP_PATH "${ROCM_PATH}/hip")
  set(HIP_CLANG_PATH "${ROCM_PATH}/llvm/bin")
  set(CMAKE_MODULE_PATH "${HIP_PATH}/cmake" ${CMAKE_MODULE_PATH})
  find_package(HIP QUIET REQUIRED)

  if(HIP_FOUND)
    message(STATUS "Found HIP: " ${HIP_VERSION})
  else()
    message(FATAL_ERROR "Could not find HIP. Ensure that HIP is either installed in /opt/rocm/hip or the variable ROCM_PATH is set.")
  endif()
endif()

find_package(cppgsl REQUIRED)

# std::filesytem detection
find_package(Filesystem REQUIRED)

if(WITH_Allen_PRIVATE_DEPENDENCIES)
  # We need a Python 3 interpreter
  find_package(Python3 REQUIRED)

  # Find libClang, required for parsing the Allen codebase
  find_package(LibClang QUIET)

  # https://github.com/nlohmann/json
  find_package(nlohmann_json REQUIRED)
  find_package(Threads REQUIRED)

  # Boost
  find_package(Boost REQUIRED COMPONENTS filesystem iostreams thread regex
    serialization program_options)

  find_package(PkgConfig)
  pkg_check_modules(zmq libzmq REQUIRED IMPORTED_TARGET)  # for ZeroMQ

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
elseif(NOT STANDALONE AND WITH_Allen_PRIVATE_DEPENDENCIES)
  find_package(ROOT REQUIRED COMPONENTS Core Hist Tree RIO Thread)
  find_package(TBB REQUIRED)
  set(ALLEN_ROOT_DEFINITIONS WITH_ROOT ROOT_CXX17)
  set(ALLEN_ROOT_LIBRARIES ${ROOT_LIBRARIES} ${TBB_LIBRARIES})
elseif(STANDALONE)
   message(STATUS "Compiling without ROOT")
endif()
