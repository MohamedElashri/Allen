###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project(Allen VERSION 1.8
        LANGUAGES CXX)

# ---------------
# Boolean options
# ---------------

option(BUILD_TESTING "Build test programs" OFF)
option(USE_ROOT "Build with ROOT" OFF)
option(USE_KALMAN_DOUBLE_PRECISION "Use double precision Kalman filter" OFF)
option(CPU_USE_REAL_HALF "Use half_t with uint16_t backend" OFF)
option(STANDALONE "Build Allen standalone" OFF)
option(TREAT_WARNINGS_AS_ERRORS "Treat all warnings as errors" OFF)
option(ALWAYS_DISPATCH_TO_DEFAULT "Dispatch architecture-specific functions always to default target" OFF)
set(SEQUENCE_BUILD_JOBS 1 CACHE STRING "Number of sequence build jobs"  )

# --------
# Settings
# --------

# for find_package and include
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

if(NOT PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
  # Fix CMAKE_MODULE_PATH when building the stack as single project
  list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
  return()
endif()

set(CMAKE_CXX_EXTENSIONS OFF) # Generate -std=c++17 instead of -std=gnu++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -DALLEN_DEBUG")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -----------------------
# Multiple-choice options
# -----------------------

# Device target architecture
set(TARGET_DEVICE CPU CACHE STRING "Target architecture of the device")
set_property(CACHE TARGET_DEVICE PROPERTY STRINGS CPU CUDA HIP)

# CPU manual vectorization target
set(CPU_STATIC_VECTOR_WIDTH OFF CACHE STRING "Define a static vector width for CPU target")
set_property(CACHE CPU_STATIC_VECTOR_WIDTH PROPERTY STRINGS OFF scalar 128bits 256bits 512bits)

# Build type (builds based on Gaudi are setting CMAKE_BUILD_TYPE in gaudi_project)
if(STANDALONE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type")
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS RelWithDebInfo Release Debug)
  message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})
endif()

# CUDA compute capability
set(CUDA_ARCH COMPATIBILITY CACHE STRING "CUDA target architecture")
set_property(CACHE CUDA_ARCH PROPERTY STRINGS COMPATIBILITY MAX MIN 53 60 61 62 70 72 75 80 86)

# HIP architecture
# https://llvm.org/docs/AMDGPUUsage.html
set(HIP_ARCH gfx908 CACHE STRING "HIP target architecture")
set_property(CACHE HIP_ARCH PROPERTY STRINGS gfx900 gfx902 gfx904 gfx906 gfx908 gfx909 gfx1010 gfx1011 gfx1012 gfx1030)

# --------------------
# Unrestricted options
# --------------------

# Sequences to build, SEQUENCE argument overrides SEQUENCES for now
set(SEQUENCES "" CACHE STRING "Sequences to build as a regex for exact matching; \"all\" builds all sequences")
if(NOT STANDALONE)
  set(SEQUENCES "hlt1_pp_default")
endif()

# Configured CPU architecture
set(CPU_ARCH native CACHE STRING "Target CPU architecture")
message(STATUS "CPU_ARCH: " ${CPU_ARCH})

# CPU static vector width
if(NOT CPU_STATIC_VECTOR_WIDTH STREQUAL "OFF")
  message(STATUS "CPU_STATIC_VECTOR_WIDTH: " ${CPU_STATIC_VECTOR_WIDTH})
  if(CPU_STATIC_VECTOR_WIDTH STREQUAL "scalar")
    add_compile_definitions(CPU_STATIC_VECTOR_WIDTH=0)
  elseif(CPU_STATIC_VECTOR_WIDTH STREQUAL "128bits")
    add_compile_definitions(CPU_STATIC_VECTOR_WIDTH=1)
  elseif(CPU_STATIC_VECTOR_WIDTH STREQUAL "256bits")
    add_compile_definitions(CPU_STATIC_VECTOR_WIDTH=2)
  elseif(CPU_STATIC_VECTOR_WIDTH STREQUAL "512bits")
    add_compile_definitions(CPU_STATIC_VECTOR_WIDTH=3)
  endif()
endif()

# Dispatch configuration
if(ALWAYS_DISPATCH_TO_DEFAULT)
  message(STATUS "ALWAYS_DISPATCH_TO_DEFAULT: " ${ALWAYS_DISPATCH_TO_DEFAULT})
  add_compile_definitions(ALWAYS_DISPATCH_TO_DEFAULT)
endif()


# General CMAKE CXX FLAGS option
if(TREAT_WARNINGS_AS_ERRORS)
  message(STATUS "Treating compiler warnings as errors")
  if (TARGET_DEVICE STREQUAL "CUDA")
    string(APPEND CMAKE_CUDA_FLAGS " -Xcompiler=-Werror")
  endif()
  string(APPEND CMAKE_CXX_FLAGS " -Werror")
endif()

# Choice of malloc engine
set(MALLOC_ENGINE SINGLE_ALLOC CACHE STRING "Malloc engine")
set_property(CACHE MALLOC_ENGINE PROPERTY STRINGS SINGLE_ALLOC MULTI_ALLOC)
message(STATUS "Memory manager: " ${MALLOC_ENGINE})
add_compile_definitions(MEMORY_MANAGER_${MALLOC_ENGINE})

# Choice of device invocation synchronicity
option(SYNCHRONOUS_DEVICE_EXECUTION "Make device calls synchronous" OFF)
message(STATUS "Synchronous device execution: " ${SYNCHRONOUS_DEVICE_EXECUTION})
if(SYNCHRONOUS_DEVICE_EXECUTION)
  add_compile_definitions(SYNCHRONOUS_DEVICE_EXECUTION)
endif()

# Choice of enabling contracts
option(ENABLE_CONTRACTS "Enable contracts in sequence execution" OFF)
message(STATUS "Contracts: " ${ENABLE_CONTRACTS})
if(ENABLE_CONTRACTS)
  add_compile_definitions(ENABLE_CONTRACTS)
endif()

# Chioce of profiling with callgrind
option(CALLGRIND_PROFILE "Set Callgrind macros around sequence" OFF)
if(CALLGRIND_PROFILE)
  add_compile_definitions(CALLGRIND_PROFILE)
endif()

if (NOT STANDALONE)
  set(WITH_Allen_PRIVATE_DEPENDENCIES TRUE)
endif()
include(AllenDependencies) # public deps

if (NOT STANDALONE)
  message(STATUS "LHCb stack build")

  set(target_hip FALSE)
  set(target_cuda FALSE)

  string(REPLACE "+" ";" compiler_split "${LCG_COMPILER}")
  foreach(device_comp IN LISTS compiler_split)
    if ("${device_comp}" MATCHES "cuda([0-9]+)_([0-9]+)((gcc|clang)([0-9]+))?")
      set(target_cuda TRUE)
    elseif ("${device_comp}" STREQUAL "hip")
      set(target_hip TRUE)
    endif()
  endforeach()

  if (${target_hip} AND NOT ${target_cuda})
    set(TARGET_DEVICE "HIP")
  elseif(${target_cuda} AND NOT ${target_hip})
    set(TARGET_DEVICE "CUDA")
  elseif(${target_cuda} AND ${target_hip})
  	message(FATAL_ERROR "Cannot simultaneously build for HIP and CUDA targets")
  else()
	set(TARGET_DEVICE "CPU")
  endif()

  message(STATUS "Allen device target: " ${TARGET_DEVICE})
  set(TARGET_DEFINITION "TARGET_DEVICE_${TARGET_DEVICE}")

  lhcb_add_subdirectories(
    Rec/Allen
    Dumpers/BinaryDumpers
    Dumpers/RootDumpers)
else()
  message(STATUS "Allen device target: " ${TARGET_DEVICE})
  set(TARGET_DEFINITION "TARGET_DEVICE_${TARGET_DEVICE}")
endif()

# Set the policy of CMP0104 (require CUDA_ARCHITECTURES) to OLD.
# Support it in a future Allen release.
if(${CMAKE_VERSION} VERSION_GREATER "3.18.0" OR ${CMAKE_VERSION} VERSION_EQUAL "3.18.0")
  cmake_policy(SET CMP0104 OLD)
endif()

# List of all expected submodules
set(EXPECTED_SUBMODULES umesimd)
foreach(SUBMODULE ${EXPECTED_SUBMODULES})
  if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/${SUBMODULE}/CMakeLists.txt")
    message(FATAL_ERROR "Submodule ${SUBMODULE} was not downloaded! Please update submodules and try again. You may need to run `git submodule update --init --recursive`.")
  endif()
endforeach()

# Detect CUDA architecture
if(TARGET_DEVICE STREQUAL "CUDA")
  if (NOT CMAKE_CUDA_COMPILER)
    find_program(CMAKE_CUDA_COMPILER nvcc
                 HINTS /usr/local/cuda/bin)
    if (CMAKE_CUDA_COMPILER)
      message(STATUS "Found CUDA compiler ${CMAKE_CUDA_COMPILER}")
    endif()
  else()
    message(STATUS "Using CUDA compiler ${CMAKE_CUDA_COMPILER}")
  endif()
#Settings can be overriden by setting OVERRIDE_CUDA_ARCH_FLAG
  if(DEFINED OVERRIDE_CUDA_ARCH_FLAG AND NOT OVERRIDE_CUDA_ARCH_FLAG STREQUAL "")
    message(STATUS "Overriding CUDA architecture setting.")
    set(DEVICE_ARCHITECTURE "${OVERRIDE_CUDA_ARCH_FLAG}")
  else()
    set(CUDA_ARCH_LIST)
  #CUDA_ARCH can be set to MAX
    if(CUDA_ARCH STREQUAL "MAX")
      set(OUTPUTFILE ${CMAKE_BINARY_DIR}/cuda_arch) # No suffix required
      set(CUDAFILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/cuda_arch.cu)
      execute_process(COMMAND ${CMAKE_CUDA_COMPILER} -std=c++17 -lcuda ${CUDAFILE} -o ${OUTPUTFILE})
      if(CUDA_ARCH STREQUAL "MAX")
        set(CHECK_ARGS "-l")
      endif()
      message(STATUS "Detecting highest CUDA compute capability available...")
      execute_process(COMMAND ${OUTPUTFILE} ${CHECK_ARGS}
        RESULT_VARIABLE CUDA_RETURN_CODE
        OUTPUT_VARIABLE CUDA_ARCH_OUTPUT)

      if(${CUDA_RETURN_CODE} EQUAL 1)
        message(FATAL_ERROR "${CUDA_ARCH}")
      else()
        message(STATUS "Detected architecture: " ${CUDA_ARCH_OUTPUT})
        list(APPEND CUDA_ARCH_LIST ${CUDA_ARCH_OUTPUT})
      endif()
  #CUDA_ARCH can be set to MIN
    elseif(CUDA_ARCH STREQUAL "MIN")
      message(STATUS "Setting lowest CUDA compute capability:")
      list(APPEND CUDA_ARCH_LIST 53)
  #By default, compile for compatibility
    elseif(CUDA_ARCH STREQUAL "COMPATIBILITY")
  #Compatibility arch flag.
  #* These settings support natively archs 5.0, 6.0, 7.0, 7.5, 8.0 and 8.6.
  #* All other 5.X and 6.X architectures are supported through their respective
  #major number builds, specifics of those architectures are not used.
  #* Forward compatibility with newer devices is also supported by generating PTX from 8.6
  #(- gencode = arch = compute_86, compute = compute_86)
      message(STATUS "Setting compute capability to COMPATIBILITY:")
      foreach(arch 53 60 70 75 80 86)
        list(APPEND CUDA_ARCH_LIST ${arch})
      endforeach()
  #Finally, compile for the specified architecture
    else()
      message(STATUS "Setting architecture " ${CUDA_ARCH})
      list(APPEND CUDA_ARCH_LIST ${CUDA_ARCH})
    endif()

    # Compatibility with CMake 3.18
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18.0")
      set(CMAKE_CUDA_ARCHITECTURES ${CUDA_ARCH_LIST})
    endif()

    set(DEVICE_ARCHITECTURE "")
    foreach(arch ${CUDA_ARCH_LIST})
      string(APPEND DEVICE_ARCHITECTURE " -gencode=arch=compute_${arch},code=sm_${arch}")
    endforeach()
    if(CUDA_ARCH STREQUAL "COMPATIBILITY")
      string(APPEND DEVICE_ARCHITECTURE " -gencode=arch=compute_86,code=compute_86")
    endif()
  endif()
  message(STATUS "Device architecture set to ${DEVICE_ARCHITECTURE}")
endif()

include(ConfigurationUtils)

# Setup project for the configured target
if(TARGET_DEVICE STREQUAL "CPU")
  # This seems to be needed across compilers
  add_definitions("-x c++")

  if(CPU_USE_REAL_HALF)
    add_compile_definitions(CPU_USE_REAL_HALF)
  endif()

  function(allen_add_host_library)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})

    install(TARGETS ${ARGV0} LIBRARY DESTINATION lib)
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
  endfunction()

  function(allen_add_device_library)
    set(destination lib)
    list(FIND ARGV STREAM is_stream)
    list(FILTER ARGV EXCLUDE REGEX "STREAM")

    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})

    if (NOT ${is_stream} EQUAL -1)
      set(destination lib/sequences)
    endif()

    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0}
      EXPORT Allen
      DESTINATION ${destination})
  endfunction()

  function(allen_add_executable)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_executable(${ARGV})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin)
  endfunction()

  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0)
    string(APPEND CMAKE_CXX_FLAGS " -Wno-maybe-uninitialized")
   endif()

elseif(TARGET_DEVICE STREQUAL "HIP")

  # Setup HIPCC compiler
  if(NOT DEFINED ROCM_PATH)
    if(NOT DEFINED ENV{ROCM_PATH})
      set(ROCM_PATH "/opt/rocm" CACHE PATH "Path where ROCM has been installed")
    else()
      set(ROCM_PATH $ENV{ROCM_PATH} CACHE PATH "Path where ROCM has been installed")
    endif()
  endif()

  # Find HIP
  set(HIP_PATH "${ROCM_PATH}/hip")
  set(HIP_CLANG_PATH "${ROCM_PATH}/llvm/bin")
  set(CMAKE_MODULE_PATH "${HIP_PATH}/cmake" ${CMAKE_MODULE_PATH})
  find_package(HIP QUIET REQUIRED)
  if(HIP_FOUND)
    message(STATUS "Found HIP: " ${HIP_VERSION})
  else()
    message(FATAL_ERROR "Could not find HIP. Ensure that HIP is either installed in /opt/rocm/hip or the variable ROCM_PATH is set.")
  endif()

  # Deal with build type (HIP)
  if(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set(HIP_RELEASE_OPTIONS "-O3 -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(HIP_RELEASE_OPTIONS "-g -DNDEBUG")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif()
  set(HIPCC_OPTIONS "${HIP_RELEASE_OPTIONS} -fPIC -std=c++17 --amdgpu-target=${HIP_ARCH}")

  function(allen_add_host_library)
    add_library(${ARGV})
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION lib)
  endfunction()

  function(allen_add_device_library)
    set(destination lib)
    list(FIND ARGV STREAM is_stream)
    list(FILTER ARGV EXCLUDE REGEX "STREAM")

    if (NOT ${is_stream} EQUAL -1)
      set(destination lib/sequences)
    endif()

    hip_add_library(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})

    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})

    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION ${destination})
  endfunction()

  function(allen_add_executable)
    hip_add_executable(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin)
  endfunction()
elseif(TARGET_DEVICE STREQUAL "CUDA")
  enable_language(CUDA)

  set(CMAKE_CUDA_STANDARD 17)
  set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG --generate-line-info")
  set(CMAKE_CUDA_FLAGS_RELEASE "-O3 -DNDEBUG --generate-line-info")
  set(CMAKE_CUDA_FLAGS_DEBUG "-G -g -DALLEN_DEBUG")
  set(CUDA_PROPAGATE_HOST_FLAGS OFF)

  option(CUDA_VEBOSE_BUILD "CUDA verbose build" OFF)
  if (CUDA_VERBOSE_BUILD)
    set(CUDA_VERBOSE_FLAGS "--resource-usage --verbose --nvlink-options=--verbose -Xptxas=--verbose")
  else()
    set(CUDA_VERBOSE_FLAGS "")
  endif()

  string(APPEND CMAKE_CUDA_FLAGS " ${DEVICE_ARCHITECTURE} -Xcudafe --display_error_number --use_fast_math --expt-relaxed-constexpr ${CUDA_VERBOSE_FLAGS}")

  message(STATUS "Detected CUDA include directory: " ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

  function(allen_add_host_library)
    set(destination lib)
    list(FIND ARGV STREAM is_stream)
    list(FILTER ARGV EXCLUDE REGEX "STREAM")

    if (NOT ${is_stream} EQUAL -1)
      set(destination lib/sequences)
    endif()

    add_library(${ARGV})

    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION ${destination})
  endfunction()

  function(allen_add_device_library)
    set(destination lib)
    list(FIND ARGV STREAM is_stream)
    list(FILTER ARGV EXCLUDE REGEX "STREAM")

    if (NOT ${is_stream} EQUAL -1)
      set(destination lib/sequences)
    endif()

    add_library(${ARGV})

    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION ${destination})
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin)
  endfunction()

  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 9.0)
    string(APPEND CMAKE_CXX_FLAGS " -Wno-maybe-uninitialized")
  endif()
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  string(APPEND CMAKE_CXX_FLAGS " -Wno-gnu-zero-variadic-macro-arguments")
endif()

if(STANDALONE)
  #Detect target CPU architecture
  include(TargetArch)
  set(TARGET_CPU_ARCHITECTURE "")
  target_architecture(TARGET_CPU_ARCHITECTURE)
  message(STATUS "Detected CPU architecture: ${TARGET_CPU_ARCHITECTURE}")

  #Specific optimizations for different architectures
  if(TARGET_CPU_ARCHITECTURE STREQUAL "x86_64" OR TARGET_CPU_ARCHITECTURE STREQUAL "i386"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "ia64")
  #x86 family
    string(APPEND CMAKE_CXX_FLAGS " -march=${CPU_ARCH}")
  elseif(TARGET_CPU_ARCHITECTURE STREQUAL "ppc" OR TARGET_CPU_ARCHITECTURE STREQUAL "ppc64")
  #PowerPC family
  #More options on : https: // developer.ibm.com/linuxonpower/compiler-options-table/
    string(APPEND CMAKE_CXX_FLAGS " -mcpu=${CPU_ARCH}")
  elseif(TARGET_CPU_ARCHITECTURE STREQUAL "arm" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv5"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "armv6" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv7")
  #ARM family
    string(APPEND CMAKE_CXX_FLAGS " -march=${CPU_ARCH}")
  elseif(TARGET_CPU_ARCHITECTURE STREQUAL "aarch64")
  #ARM64 family
  #Options from : http: // www.prace-ri.eu/IMG/pdf/Best-Practice-Guide-ARM64.pdf
    string(APPEND CMAKE_CXX_FLAGS " -march=${CPU_ARCH} -floop-optimize \
    -falign-loops -falign-labels -falign-functions -falign-jumps -fomit-frame-pointer")
  elseif(TARGET_CPU_ARCHITECTURE STREQUAL "apple_silicon")
  # Apple silicon
    string(APPEND CMAKE_CXX_FLAGS " -mcpu=${CPU_ARCH}")
  endif()
endif()

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()

# Determine which sequences to generate or copy configurations for
file(GLOB available_sequences "configuration/sequences/*.py")
set(BUILD_SEQUENCES "")
foreach(sequence_filename ${available_sequences})
  get_filename_component(sequence ${sequence_filename} NAME_WE)
  string(REGEX MATCH "^${SEQUENCES}\$" sequence_matches ${sequence})
  if (sequence_matches OR "${SEQUENCES}" STREQUAL "all")
    list(APPEND BUILD_SEQUENCES ${sequence})
  endif()
endforeach()

if(NOT BUILD_SEQUENCES)
  message(FATAL_ERROR "No sequences selected to be built with pattern ${SEQUENCES}.")
endif()

set(EXTERNAL_DIR "external")

if(BUILD_TESTING)
  add_subdirectory(external/Catch2)
  add_subdirectory(test/unit_tests)
endif()

add_subdirectory(configuration)
add_subdirectory(backend)
add_subdirectory(host)
add_subdirectory(device)
add_subdirectory(checker)
add_subdirectory(mdf)
add_subdirectory(integration)
add_subdirectory(zmq)
add_subdirectory(stream)

#Main Allen executable
file(GLOB common_sources "main/src/*.cpp")
set(allen_lib_sources)

#Remove main.cpp from common_sources
foreach(source main Allen AllenThreads OutputHandler ZMQOutputSender Provider RegisterConsumers)
  get_filename_component(${source}_cpp_path ${CMAKE_CURRENT_SOURCE_DIR}/main/src/${source}.cpp ABSOLUTE)
  list(REMOVE_ITEM common_sources "${${source}_cpp_path}")
endforeach()

set(allen_lib_sources
  ${Allen_cpp_path}
  ${AllenThreads_cpp_path}
  ${OutputHandler_cpp_path}
  ${ZMQOutputSender_cpp_path}
  ${Provider_cpp_path}
  ${RegisterConsumers_cpp_path})

# Interface library that will be used for common functionality
add_library(AllenCommon INTERFACE)
target_include_directories(AllenCommon
  INTERFACE
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/main/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/test/contracts/include>)
target_include_directories(AllenCommon INTERFACE SYSTEM
  ${CPPGSL_INCLUDE_DIR}
  ${Boost_INCLUDE_DIRS})


set(AllenHeaders)
foreach(header
    Allen.h
    Provider.h
    SystemOfUnits.h
    Logger.h
    Timer.h
    LoggerCommon.h
    BankTypes.h
    BankMapping.h
    Common.h
    AllenUnits.h
    MEPTools.h
    InputProvider.h
    SliceUtils.h
    TransposeTypes.h)
  list(APPEND AllenHeaders main/include/${header})
endforeach()

set_target_properties(Common PROPERTIES PUBLIC_HEADER "${AllenHeaders}")
install(TARGETS Common EXPORT Allen
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Allen)

#Make sure extra search paths get included as system to avoid
#warnings in external headers
if (DEFINED ENV{CPLUS_INCLUDE_PATH})
  target_include_directories(AllenCommon SYSTEM INTERFACE $ENV{CPLUS_INCLUDE_PATH})
elseif (DEFINED ENV{CPATH})
  target_include_directories(AllenCommon SYSTEM INTERFACE $ENV{CPATH})
endif()

if (TARGET_DEVICE STREQUAL "CUDA")
  find_package(CUDAToolkit)
  target_link_libraries(AllenCommon PUBLIC CUDA::cudart)
  target_include_directories(AllenCommon SYSTEM INTERFACE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
elseif(TARGET_DEVICE STREQUAL "HIP")
  # find_package(hip) doesn't work as hip-targets.cmake is not relocatable
  find_library(hip_runtime_lib amdhip64 HINTS ${HIP_PATH}/lib REQUIRED)
  target_link_libraries(AllenCommon PUBLIC ${hip_runtime_lib})
endif()

# Use std::filesystem or Boost filesystem depeding on availability
add_library(AllenFS INTERFACE)
install(TARGETS AllenFS EXPORT Allen)
if(NOT Filesystem_FOUND)
  target_compile_definitions(AllenFS INTERFACE USE_BOOST_FILESYSTEM)
  target_link_libraries(AllenFS INTERFACE Boost::filesystem)
else()
  target_link_libraries(AllenFS INTERFACE std::filesystem)
endif()

find_package(Threads REQUIRED)

# Add host library
allen_add_host_library(HostCommon STATIC ${common_sources})

target_include_directories(HostCommon PUBLIC
  PRIVATE
  SYSTEM ${ZMQ_INCLUDE_DIRS}
  ${CMAKE_SOURCE_DIR}/Dumpers/BinaryDumpers
  ${CMAKE_SOURCE_DIR}/Dumpers/RootDumpers
  ${CMAKE_SOURCE_DIR}/backend/include
  ${CMAKE_SOURCE_DIR}/integration/non_event_data/include
  ${CMAKE_SOURCE_DIR}/checker/tracking/include)

message(STATUS "CMAKE CXX FLAGS: " ${CMAKE_CXX_FLAGS})

target_link_libraries(HostCommon PRIVATE AllenFS nlohmann_json::nlohmann_json
  EventModel Gear Backend mdf NonEventData Common LHCbEvent)

target_link_libraries(AllenCommon PUBLIC mdf AllenFS nlohmann_json::nlohmann_json)

allen_add_host_library(AllenLib SHARED ${allen_lib_sources})

target_link_libraries(AllenLib PUBLIC
  Stream
  HostCommon
  AllenCommon
  HostEventModel
  TrackChecking
  PVChecking
  CheckClustering
  SelChecking
  Monitoring
  NonEventData
  AllenZMQ
  HostCombiners
  Threads::Threads
  Backend
  EventModel
  Gear
  mdf
  LHCbEvent
  ${CMAKE_DL_LIBS})

target_compile_definitions(AllenLib PUBLIC ${TARGET_DEFINITION})


if (USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(AllenLib PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_compile_definitions(AllenLib PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(AllenLib SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  target_link_libraries(AllenLib PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

if (NOT STANDALONE)
  target_include_directories(AllenLib PUBLIC ${AIDA_INCLUDE_DIRS})
endif()

allen_add_executable(Allen ${main_cpp_path})

target_link_libraries(Allen PRIVATE AllenLib)

if (NOT STANDALONE)
  target_link_libraries(Allen PRIVATE fmt::fmt)

  gaudi_install(CMAKE cmake/modules)

  # Finalize configuration
  lhcb_finalize_configuration()
endif()
