###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

# For STANDALONE and cmake versions under 3.21, allow using
# the env var CMAKE_TOOLCHAIN_FILE to specify the toolchain
if(STANDALONE AND NOT DEFINED CMAKE_TOOLCHAIN_FILE AND DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
  set(CMAKE_TOOLCHAIN_FILE $ENV{CMAKE_TOOLCHAIN_FILE})
endif()

project(Allen VERSION 2.1
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
option(USE_BOOST_FILESYSTEM "Use Boost filesystem library instead of std::filesystem" OFF)

# --------
# Settings
# --------

# for find_package and include
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

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
if(STANDALONE AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS RelWithDebInfo Release Debug)
endif()
message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})

# CUDA compute capability
set(CUDA_ARCH COMPATIBILITY CACHE STRING "CUDA target architecture")
set_property(CACHE CUDA_ARCH PROPERTY STRINGS COMPATIBILITY MAX MIN 53 60 61 62 70 72 75 80 86)

# HIP architecture
# https://llvm.org/docs/AMDGPUUsage.html
set(HIP_ARCH gfx908 CACHE STRING "HIP target architecture")
set_property(CACHE HIP_ARCH PROPERTY STRINGS gfx900 gfx902 gfx904 gfx906 gfx908 gfx909 gfx1010 gfx1011 gfx1012 gfx1030)

# Forces a no separable compilation build
# Note: For now, HIP *requires* a no separable compilation build
option(SEPARABLE_COMPILATION "Sets the build to no separable compilation" ON)
if(TARGET_DEVICE STREQUAL "HIP")
  set(SEPARABLE_COMPILATION OFF)
  message(STATUS "Separable compilation: OFF (required by HIP)")
else()
  message(STATUS "Separable compilation: " ${SEPARABLE_COMPILATION})
endif()

# --------------------
# Unrestricted options
# --------------------

# Sequences to build, SEQUENCE argument overrides SEQUENCES for now
if (STANDALONE)
  set(SEQUENCES "" CACHE STRING "Sequences to build as a regex for exact matching; \"all\" builds all sequences")
else()
  set(SEQUENCES "all" CACHE STRING "Sequences to build as a regex for exact matching; \"all\" builds all sequences")
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

# Choice of profiling with callgrind
option(CALLGRIND_PROFILE "Set Callgrind macros around sequence" OFF)
if(CALLGRIND_PROFILE)
  add_compile_definitions(CALLGRIND_PROFILE)
endif()

set(WITH_Allen_PRIVATE_DEPENDENCIES TRUE)
include(AllenDependencies)

set(TARGET_DEFINITION "TARGET_DEVICE_${TARGET_DEVICE}")

include(CTest)

if (NOT STANDALONE)
  # Disable messages from the LHCb configuration checks that fire as
  # a result of the different directory/source structure of Allen
  if(PROJECT_NAME STREQUAL CMAKE_PROJECT_NAME)
    set(LHCB_UNUSED_SUBDIR_MESSAGE_TYPE "VERBOSE")
    set(LHCB_UNUSED_SOURCE_MESSAGE_TYPE "IGNORE")
  endif()

  lhcb_add_subdirectories(
    Rec/Allen
    Dumpers/BinaryDumpers
    Dumpers/RootDumpers)

  lhcb_env(
    SET ALLEN_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
    SET ALLEN_PROJECT_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
endif()

# Set the policy of CMP0104 (require CUDA_ARCHITECTURES) to OLD.
# Support it in a future Allen release.
if(${CMAKE_VERSION} VERSION_GREATER "3.18.0" OR ${CMAKE_VERSION} VERSION_EQUAL "3.18.0")
  cmake_policy(SET CMP0104 OLD)
endif()

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
      set(OUTPUTFILE ${PROJECT_BINARY_DIR}/cuda_arch) # No suffix required
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
      string(APPEND DEVICE_ARCHITECTURE " -gencode=arch=compute_86,code=sm_86")
    endif()
  endif()
  message(STATUS "Device architecture set to ${DEVICE_ARCHITECTURE}")
endif()

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
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION lib)
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
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
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
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin)
  endfunction()

  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0)
    string(APPEND CMAKE_CXX_FLAGS " -Wno-maybe-uninitialized")
   endif()

elseif(TARGET_DEVICE STREQUAL "HIP")
  # Deal with build type (HIP)
  if(NOT CMAKE_BUILD_TYPE)
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set(HIP_RELEASE_OPTIONS "-O3 -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(HIP_RELEASE_OPTIONS "-O0 -g -DALLEN_DEBUG")
  endif()

  if(GCC_TOOLCHAIN_ROOT)
    set(HIP_TOOLCHAIN_OPTIONS "--gcc-toolchain=${GCC_TOOLCHAIN_ROOT}")
  else()
    execute_process(COMMAND ${CMAKE_CXX_COMPILER} -print-libgcc-file-name OUTPUT_VARIABLE lib_gcc_file_raw)
    string(REGEX REPLACE "/lib/gcc.*\n" "" cxx_idir ${lib_gcc_file_raw})
    set(HIP_TOOLCHAIN_OPTIONS "--gcc-toolchain=${cxx_idir}")
  endif()

  message(STATUS "HIP GCC TOOLCHAIN: " ${HIP_TOOLCHAIN_OPTIONS})
  set(HIPCC_OPTIONS "${HIP_RELEASE_OPTIONS} ${HIP_TOOLCHAIN_OPTIONS} -fPIC -std=c++17 --amdgpu-target=${HIP_ARCH}")

  # Add the origin directory
  set(CMAKE_EXE_LINKER_FLAGS "-Wl,-rpath,./")

  function(allen_add_host_library)
    add_library(${ARGV})
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
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
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)

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

  string(APPEND CMAKE_CUDA_FLAGS " ${DEVICE_ARCHITECTURE} ${CUDA_TOOLCHAIN_OPTIONS} -Xcudafe --display_error_number --use_fast_math --expt-relaxed-constexpr ${CUDA_VERBOSE_FLAGS}")
  if (NOT CMAKE_CUDA_HOST_COMPILER)
    string(REGEX REPLACE "toolchain/.*" "toolchain" CXX_COMPILER_DIR ${CMAKE_CXX_COMPILER})
    string(APPEND CMAKE_CUDA_FLAGS " -ccbin=${CXX_COMPILER_DIR} ")
  endif()

  message(STATUS "CMAKE CUDA FLAGS:" ${CMAKE_CUDA_FLAGS})
  message(STATUS "Detected CUDA include directory: " ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

  function(allen_add_host_library)
    set(destination lib)
    list(FIND ARGV STREAM is_stream)
    list(FILTER ARGV EXCLUDE REGEX "STREAM")

    if (NOT ${is_stream} EQUAL -1)
      set(destination lib/sequences)
    endif()

    add_library(${ARGV})
    if(SEPARABLE_COMPILATION)
      set_property(TARGET ${ARGV0} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
    endif()
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES} ${PROJECT_BINARY_DIR}/code_generation)
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
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
    if(SEPARABLE_COMPILATION)
      set_property(TARGET ${ARGV0} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
    endif()
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION} ODIN_WITHOUT_GAUDI)
    add_library(Allen::${ARGV0} ALIAS ${ARGV0})
    install(TARGETS ${ARGV0}
      EXPORT Allen
      LIBRARY DESTINATION ${destination})
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    if(SEPARABLE_COMPILATION)
      set_property(TARGET ${ARGV0} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
    endif()
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin)
  endfunction()

  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 9.0)
    string(APPEND CMAKE_CXX_FLAGS " -Wno-maybe-uninitialized")
  endif()
endif()

# Mechanism to mimic a UNITY build
set(COUNTER 0)
set(GROUPCOMP_DIR ${PROJECT_BINARY_DIR}/group_comp)
file(MAKE_DIRECTORY ${GROUPCOMP_DIR})

function(allen_add_device_library_unified)
  set(destination lib)

  foreach(arg IN LISTS ARGN)
    if(${arg} MATCHES "\\.cu$")
      list(APPEND LIBRARY_SOURCES ${arg})
    else()
      list(APPEND LIBRARY_SETTINGS ${arg})
    endif()
  endforeach()

  set(UNIFIED_FILENAME "${GROUPCOMP_DIR}/group_${COUNTER}.cu")
  add_custom_command(
    OUTPUT "${UNIFIED_FILENAME}"
    COMMAND ${CMAKE_COMMAND} -E remove "${UNIFIED_FILENAME}" && cat ${LIBRARY_SOURCES} >> "${UNIFIED_FILENAME}"
    DEPENDS "${LIBRARY_SOURCES}")

  if(TARGET_DEVICE STREQUAL "CPU")
    add_library(${LIBRARY_SETTINGS} ${UNIFIED_FILENAME})
    set_source_files_properties(${UNIFIED_FILENAME} PROPERTIES LANGUAGE CXX)
  elseif(TARGET_DEVICE STREQUAL "HIP")
    hip_add_library(${LIBRARY_SETTINGS} ${UNIFIED_FILENAME} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
  elseif(TARGET_DEVICE STREQUAL "CUDA")
    add_library(${LIBRARY_SETTINGS} ${UNIFIED_FILENAME})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
  endif()

  target_sources(${ARGV0} PRIVATE ${UNIFIED_FILENAME} ${LIBRARY_SOURCES})
  add_library(Allen::${ARGV0} ALIAS ${ARGV0})
  target_compile_definitions(${ARGV0} PRIVATE ${TARGET_DEFINITION})

  install(TARGETS ${ARGV0}
    EXPORT Allen
    LIBRARY DESTINATION ${destination})

  MATH(EXPR COUNTER "${COUNTER}+1")
endfunction()

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  string(APPEND CMAKE_CXX_FLAGS " -Wno-gnu-zero-variadic-macro-arguments")
endif()

if(STANDALONE)
  string(REGEX MATCH "-march=[^ ]*" march_is_set ${CMAKE_CXX_FLAGS})
  if(NOT march_is_set)
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
endif()

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()

# Determine which sequences to generate or copy configurations for
file(GLOB available_sequences CONFIGURE_DEPENDS "configuration/sequences/*.py")
set(BUILD_SEQUENCES "")
foreach(sequence_filename ${available_sequences})
  get_filename_component(sequence ${sequence_filename} NAME_WE)
  string(REGEX MATCH "^${SEQUENCES}\$" sequence_matches ${sequence})
  if (sequence_matches OR "${SEQUENCES}" STREQUAL "all")
    list(APPEND BUILD_SEQUENCES ${sequence})
  endif()
endforeach()

if(BUILD_TESTING)
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

# Interface library that will be used for common functionality
add_library(AllenCommon INTERFACE)
target_include_directories(AllenCommon
  INTERFACE
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/main/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/test/contracts/include>)

if (STANDALONE)
  target_compile_definitions(AllenCommon INTERFACE ALLEN_STANDALONE)
endif()

set(AllenHeaders)
foreach(header
    Allen.h
    Provider.h
    SystemOfUnits.h
    Logger.h
    AllenIO.h
    Timer.h
    LoggerCommon.h
    BankTypes.h
    BankMapping.h
    Common.h
    AllenUnits.h
    MEPTools.h
    InputProvider.h
    OutputHandler.h
    SliceUtils.h
    FileSystem.h
    TransposeTypes.h)
  list(APPEND AllenHeaders main/include/${header})
endforeach()

set_target_properties(AllenCommon PROPERTIES PUBLIC_HEADER "${AllenHeaders}")
install(TARGETS AllenCommon EXPORT Allen
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Allen)

#Make sure extra search paths get included as system to avoid
#warnings in external headers
if (DEFINED ENV{CPLUS_INCLUDE_PATH})
  target_include_directories(AllenCommon SYSTEM INTERFACE $ENV{CPLUS_INCLUDE_PATH})
elseif (DEFINED ENV{CPATH})
  target_include_directories(AllenCommon SYSTEM INTERFACE $ENV{CPATH})
endif()

# Use std::filesystem or Boost filesystem depeding on availability
add_library(AllenFS INTERFACE)
install(TARGETS AllenFS EXPORT Allen)
if(NOT Filesystem_FOUND OR USE_BOOST_FILESYSTEM)
  target_compile_definitions(AllenFS INTERFACE USE_BOOST_FILESYSTEM)
  target_link_libraries(AllenFS INTERFACE Boost::filesystem)
else()
  target_link_libraries(AllenFS INTERFACE std::filesystem)
endif()

message(STATUS "CMAKE CXX FLAGS: " ${CMAKE_CXX_FLAGS})


# Add host library
allen_add_host_library(HostCommon STATIC
  main/src/BankTypes.cpp
  main/src/InputReader.cpp
  main/src/InputTools.cpp
  main/src/Logger.cpp
  main/src/ProgramOptions.cpp
  main/src/ROOTService.cpp
  main/src/SliceUtils.cpp
  main/src/Timer.cpp
  main/src/Tools.cpp
  main/src/Transpose.cpp)

target_link_libraries(AllenCommon INTERFACE
  LHCbEvent AllenFS nlohmann_json::nlohmann_json cppgsl::cppgsl)
target_link_libraries(HostCommon PRIVATE
  mdf EventModel Gear Backend mdf NonEventData AllenCommon LHCbEvent Boost::iostreams)

allen_add_host_library(AllenLib SHARED
  main/src/Allen.cpp
  main/src/AllenThreads.cpp
  main/src/OutputHandler.cpp
  main/src/Provider.cpp
  main/src/RegisterConsumers.cpp
  main/src/ZMQOutputSender.cpp)

target_compile_definitions(AllenLib PUBLIC ${TARGET_DEFINITION})

target_link_libraries(AllenLib
  PRIVATE
    Backend
    Stream
    HostCommon
    HostEventModel
    NonEventData
    TrackChecking
    PVChecking
    CheckClustering
    SelChecking
    Monitoring
    HostCombiners
    EventModel
    Gear
    mdf
    LHCbEvent
  PUBLIC
    AllenCommon
    AllenRuntime
    Threads::Threads
    AllenZMQ
    ${CMAKE_DL_LIBS})

# To propagate filesystem includes/libs
target_link_libraries(AllenLib PRIVATE AllenFS)

if (USE_ROOT)
  target_link_libraries(AllenCommon INTERFACE ROOT::RIO ROOT::Core ROOT::Cling ROOT::Hist ROOT::Tree TBB::tbb)
  target_compile_definitions(AllenCommon INTERFACE ${ALLEN_ROOT_DEFINITIONS})
endif()

if (NOT STANDALONE)
  target_link_libraries(AllenLib PRIVATE AIDA::aida)
endif()

allen_add_executable(Allen main/src/main.cpp)

target_link_libraries(Allen PRIVATE AllenLib NonEventData)

if (NOT STANDALONE)
  target_link_libraries(Allen PRIVATE fmt::fmt)

  gaudi_install(CMAKE cmake/modules)

  # Finalize configuration
  lhcb_finalize_configuration()
endif()


# Download parameter files if in STANDALONE
if (STANDALONE)
  find_package(Git REQUIRED)
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/input/PARAM/")
  SET(PARAMFILESROOT "${CMAKE_CURRENT_SOURCE_DIR}/input/PARAM/ParamFiles/")
  add_custom_command(
    OUTPUT "${PARAMFILESROOT}"
    COMMENT "Checking out parameterization files from the LHCb stack"
    COMMAND
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} clone https://gitlab.cern.ch/lhcb-datapkg/ParamFiles.git --no-checkout &&
      ${CMAKE_COMMAND} -E env ${GIT_EXECUTABLE} --work-tree=ParamFiles --git-dir=ParamFiles/.git checkout origin/master -- data
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/input/PARAM/")
  add_custom_target(checkout_param_files DEPENDS "${PARAMFILESROOT}")
  add_dependencies(AllenLib checkout_param_files)
  add_compile_definitions(PARAMFILESROOTPATH=${PARAMFILESROOT})
  message(STATUS "PARAMFILESROOT set to ${PARAMFILESROOT}")
endif()
