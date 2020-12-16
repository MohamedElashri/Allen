###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

# ---------------
# Boolean options
# ---------------

option(BUILD_TESTS "Build test programs" OFF)
option(USE_ROOT "Build with ROOT" OFF)
option(USE_MPI "Build the MPI sender and enable receiving MEPs over MPI" OFF)
option(USE_KALMAN_DOUBLE_PRECISION "Use double precision Kalman filter" OFF)
option(CPU_USE_REAL_HALF "Use half_t with uint16_t backend" OFF)
option(STANDALONE "Build Allen standalone" OFF)
option(TREAT_WARNINGS_AS_ERRORS "Treat all warnings as errors" OFF)
option(ALWAYS_DISPATCH_TO_DEFAULT "Dispatch architecture-specific functions always to default target" OFF)
option(SEQUENCE_GENERATION "Sequence generation" ON)

# --------
# Settings
# --------

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX}) # for find_package
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake) # for find_package

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
set_property(CACHE TARGET_DEVICE PROPERTY STRINGS CPU CUDA HIP CUDACLANG)

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
set(HIP_ARCH gfx906 CACHE STRING "HIP target architecture")
set_property(CACHE HIP_ARCH PROPERTY STRINGS gfx900 gfx902 gfx904 gfx906 gfx908 gfx909 gfx1010 gfx1011 gfx1012)

# --------------------
# Unrestricted options
# --------------------

# Configured sequence
set(SEQUENCE hlt1_pp_default CACHE STRING "Configured sequence")
message(STATUS "Configured sequence: " ${SEQUENCE})

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

# Deal with device target architecture
if(NOT STANDALONE)
  message(STATUS "Configured Gaudi build")
  if(FORCE_CUDA)
    message(STATUS "Configured Gaudi build - CUDA target")
  else()
    message(STATUS "Configured Gaudi build - CPU target")
    set(TARGET_DEVICE "CPU")
  endif()
elseif(TARGET_DEVICE STREQUAL "HIP")
#Note : HIP with nvcc backend is not supported
#Instead, compile with CUDA target
  if(HIP_PLATFORM STREQUAL "nvcc")
    message(STATUS "HIP with nvcc backend is not supported (HIP_PLATFORM=nvcc)")
    message(STATUS "Please unset HIP_PLATFORM to trigger a HIP compilation")
    message(STATUS "Continuing with CUDA backend")
    set(TARGET_DEVICE "CUDA")
  else()
    message(STATUS "Note: Support for HIP is experimental")
  endif()
elseif(TARGET_DEVICE STREQUAL "CUDACLANG")
message(STATUS "Note: Support for CUDACLANG is experimental")
endif()
message(STATUS "Allen device target: " ${TARGET_DEVICE})

# Add compile definition for target
set(TARGET_DEFINITION "TARGET_DEVICE_${TARGET_DEVICE}")

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

#Setup the project to build as a Gaudi project or else standalone
macro(allen_project)
#Gaudi build
  if (NOT STANDALONE)
    find_package(GaudiProject REQUIRED)

#Declare project name and version
    gaudi_project(Allen v1r1 USE Rec v31r2)

#Always enable tests for gaudi builds
    set(BUILD_TESTS ON)

#Always enable ROOT for Gaudi builds
    set(USE_ROOT ON)

# FIXME: Remove once USE_DD4HEP is properly propagated
    if (TARGET Detector::DetectorLib)
      message(STATUS "Using DD4HEP")
      if (NOT DEFINED USE_DD4HEP)
        set(USE_DD4HEP ON CACHE BOOL "Controls whether DD4hep is used for the subdetectors supporting it")
      endif()
    else()
      message(STATUS "Using DetDesc")
    endif()

#Find the CUDA compiler if it's not set
#FIXME : this assumes a standard device install : re - evaluate if
#LCG_XXdeviceYY is used
    if (TARGET_DEVICE STREQUAL "CUDA")
      if (NOT CMAKE_CUDA_COMPILER)
        find_program(CMAKE_CUDA_COMPILER nvcc
                     HINTS /usr/local/cuda/bin)
        if (CMAKE_CUDA_COMPILER)
          message(STATUS "Found CUDA compiler ${CMAKE_CUDA_COMPILER}")
        endif()
      else()
        message(STATUS "Using CUDA compiler ${CMAKE_CUDA_COMPILER}")
      endif()
#Make sure the lcg compiler wrapper scripts are used to call
#the host compiler
      set(CMAKE_CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
    endif()

    find_package(cppgsl REQUIRED)
  else()
    project(Allen C CXX)
    if (BUILD_TESTS)
      enable_testing()
    endif()

    find_package(cppgsl QUIET)
    if (cppgsl_FOUND)
      message(STATUS "Found external gsl at " ${CPPGSL_INCLUDE_DIR})
    else()
      set(CPPGSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/main/cppgsl)
      message(STATUS "Using internal gsl-lite")
    endif()
  endif()
  # https://github.com/nlohmann/json
  find_package(nlohmann_json REQUIRED)
endmacro()

# Detect architecture (CUDA, CUDACLANG)
if(TARGET_DEVICE STREQUAL "CUDA" OR TARGET_DEVICE STREQUAL "CUDACLANG")
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
    if(TARGET_DEVICE STREQUAL "CUDA")
      foreach(arch ${CUDA_ARCH_LIST})
        string(APPEND DEVICE_ARCHITECTURE " -gencode=arch=compute_${arch},code=sm_${arch}")
      endforeach()
      if(CUDA_ARCH STREQUAL "COMPATIBILITY")
        string(APPEND DEVICE_ARCHITECTURE " -gencode=arch=compute_86,code=compute_86")
      endif()
    elseif(TARGET_DEVICE STREQUAL "CUDACLANG")
      foreach(arch ${CUDA_ARCH_LIST})
        string(APPEND DEVICE_ARCHITECTURE "--cuda-gpu-arch=sm_${arch} ")
      endforeach()
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
    add_library(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION lib OPTIONAL)
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
  endfunction()

  function(allen_add_device_library)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0)
    string(APPEND CMAKE_CXX_FLAGS " -Wno-maybe-uninitialized")
   endif()

   allen_project()
elseif(TARGET_DEVICE STREQUAL "HIP")
  # Setup HIPCC compiler
  if(NOT DEFINED HIP_PATH)
    if(NOT DEFINED ENV{HIP_PATH})
      set(HIP_PATH "/opt/rocm/hip" CACHE PATH "Path to which HIP has been installed")
    else()
      set(HIP_PATH $ENV{HIP_PATH} CACHE PATH "Path to which HIP has been installed")
    endif()
  endif()

  allen_project()

  # Find HIP
  set(HCC_PATH "${HIP_PATH}/../hcc")
  set(CMAKE_MODULE_PATH "${HIP_PATH}/cmake" ${CMAKE_MODULE_PATH})
  find_package(HIP QUIET REQUIRED)
  if(HIP_FOUND)
    message(STATUS "Found HIP: " ${HIP_VERSION})
  else()
    message(FATAL_ERROR "Could not find HIP. Ensure that HIP is either installed in /opt/rocm/hip or the variable HIP_PATH is set.")
  endif()

  # Set linker - This helps the linking process, which
  # at the moment fails if we set up hip_add_executable instead
  set(CMAKE_LINKER "${HIP_PATH}/bin/hipcc_cmake_linker_helper")
  set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> ${HIP_PATH}/../llvm/bin <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
  set(CMAKE_CXX_CREATE_SHARED_LIBRARY "<CMAKE_LINKER> ${HIP_PATH}/../llvm/bin <CMAKE_SHARED_LIBRARY_CXX_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <SONAME_FLAG><TARGET_SONAME> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")

  set(HIP_SEPARABLE_COMPILATION OFF)

#HCC Options(HIPCC compiler)
#Other warning options : -Wall - Wno - bitwise - op - parentheses - Wno - unused - variable - Wno - logical - op - \parentheses
  if(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set(HIP_RELEASE_OPTIONS "-O3 -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  # Note: HIP does not support asserts for now, at least in Allen:
  #       LLVM ERROR: could not scavenge SGPR to spill in entry function
  #       PLEASE submit a bug report to https://bugs.llvm.org/ and include the crash backtrace.
    message(STATUS "HIP Debug: Asserts not supported yet, setting -DNDEBUG")
    set(HIP_RELEASE_OPTIONS "-g -DNDEBUG")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif()

  # To avoid /opt/rocm/hip/include/hip/hcc_detail/hip_runtime_api.h:1695:24: warning: ignoring returned value of type ‘hipError_t’, declared with attribute nodiscard [-Wunused-result]
  string(APPEND CMAKE_CXX_FLAGS " -Wno-unused-result")

  # Note: The off warnings are there for reasons we cannot control:
  # clang-11: warning: argument unused during compilation: '--hip-device-lib-path=/local/rocm/rocm-3.5.1/lib' [-Wunused-command-line-argument]
  set(HIPCC_OPTIONS "${HIP_RELEASE_OPTIONS} -std=c++17 -Wno-unused-result -Wno-invalid-noreturn -Wno-unused-command-line-argument")

  function(allen_add_host_library)
    add_library(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${HIP_PATH}/include ${HIP_PATH}/../hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

#Define allen_add_device_library and allen_add_executable HIP specializations
  function(allen_add_device_library)
    hip_add_library(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    target_include_directories(${ARGV0} PRIVATE ${CPPGSL_INCLUDE_DIR} ${HIP_PATH}/include ${HIP_PATH}/../hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CPPGSL_INCLUDE_DIR} ${HIP_PATH}/include ${HIP_PATH}/../hsa/include)
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()
elseif(TARGET_DEVICE STREQUAL "CUDACLANG")
  allen_project()

  set(cuda_base_dir /cvmfs/sft.cern.ch/lcg/releases/cuda/10.1-6ddea/x86_64-centos7-gcc62-opt)
  set(CMAKE_LINKER ${cuda_base_dir}/bin/nvcc)

  function(allen_add_host_library)
    add_library(${ARGV})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    target_include_directories(${ARGV0} PRIVATE /cvmfs/sft.cern.ch/lcg/releases/cuda/10.1-6ddea/x86_64-centos7-gcc62-opt/include)
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  function(allen_add_device_library)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})
    set_property(TARGET ${ARGV0} PROPERTY LINKER_LANGUAGE CXX)
    target_compile_options(${ARGV0} PRIVATE -x cuda --cuda-path=${cuda_base_dir} ${DEVICE_ARCHITECTURE})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    # target_link_libraries(Threads::Threads)
  endfunction()

  function(allen_add_executable)
    message(STATUS "Please use nvcc to link the executable.")
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PRIVATE /cvmfs/sft.cern.ch/lcg/releases/cuda/10.1-6ddea/x86_64-centos7-gcc62-opt/include)
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  set (CMAKE_LINKER "/usr/local/cuda/bin/nvcc")
elseif(TARGET_DEVICE STREQUAL "CUDA")
  allen_project()
  enable_language(CUDA)

  # set(CMAKE_CUDA_STANDARD 17) # 17 not supported by current CMake version
  set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-std=c++17 -O3 -g -DNDEBUG --generate-line-info")
  set(CMAKE_CUDA_FLAGS_RELEASE "-std=c++17 -O3 -DNDEBUG --generate-line-info")
  set(CMAKE_CUDA_FLAGS_DEBUG "-std=c++17 -G -g -DALLEN_DEBUG")
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
    add_library(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  function(allen_add_device_library)
    add_library(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
    if(${CMAKE_BUILD_TYPE} MATCHES "Debug")
      # Disabling CUDA_SEPARABLE_COMPILATION has the undesired effect that DEBUG builds
      # don't link properly.
      set_target_properties(${ARGV0} PROPERTIES CUDA_SEPARABLE_COMPILATION ON CUDA_RESOLVE_DEVICE_SYMBOLS ON)
    else()
      set_target_properties(${ARGV0} PROPERTIES CUDA_RESOLVE_DEVICE_SYMBOLS ON)
    endif()
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_compile_definitions(${ARGV0} PRIVATE "-D${TARGET_DEFINITION}")
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
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
  endif()
endif()

if (USE_MPI)
  find_package(MPI REQUIRED)
#hwloc is also needed
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(HWLOC IMPORTED_TARGET hwloc)
  include_directories(SYSTEM ${MPI_CXX_INCLUDE_PATH})
  add_compile_definitions(HAVE_MPI)
else(USE_MPI)
  set(MPI_FOUND OFF)
endif()

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()

if (USE_ROOT)
   if (GaudiProject_FOUND)
     find_package(ROOT REQUIRED COMPONENTS Core Hist Tree RIO)
     find_package(TBB REQUIRED)
     set(ALLEN_ROOT_DEFINITIONS WITH_ROOT ROOT_CXX17)
     set(ALLEN_ROOT_LIBRARIES ${ROOT_LIBRARIES} ${TBB_LIBRARIES})
   else()
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

       set(ALLEN_ROOT_LIBRARIES -L$ENV{ROOTSYS}/lib -lTree -lCore -lCling -lHist -lRIO)

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
   endif()
else()
   message(STATUS "Compiling without ROOT")
endif()

set(EXTERNAL_DIR "external")

find_package(Boost REQUIRED COMPONENTS iostreams)

add_subdirectory(backend)
add_subdirectory(device)
add_subdirectory(stream)
add_subdirectory(checker)
add_subdirectory(host)
add_subdirectory(mdf)
add_subdirectory(integration)
add_subdirectory(zmq)

#Make sure extra search paths get included as system to avoid
#warnings in external headers
if (DEFINED ENV{CPLUS_INCLUDE_PATH})
  include_directories(SYSTEM $ENV{CPLUS_INCLUDE_PATH})
elseif (DEFINED ENV{CPATH})
  include_directories(SYSTEM $ENV{CPATH})
endif()

#Include directories
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(main/include)
include_directories(backend/include)
include_directories(host/velo/clustering/include)
include_directories(host/utils/prefix_sum/include)
include_directories(device/global_event_cut/include)
include_directories(device/UT/common/include)
include_directories(device/UT/compassUT/include)
include_directories(device/UT/UTDecoding/include)
include_directories(device/UT/consolidate/include)
include_directories(device/velo/common/include)
include_directories(device/velo/calculate_phi_and_sort/include)
include_directories(device/velo/consolidate_tracks/include)
include_directories(device/velo/mask_clustering/include)
include_directories(device/velo/search_by_triplet/include)
include_directories(device/velo/simplified_kalman_filter/include)
include_directories(device/PV/common/include)
include_directories(device/PV/beamlinePV/include)
include_directories(device/SciFi/common/include)
include_directories(device/SciFi/looking_forward/include)
include_directories(device/SciFi/consolidate/include)
include_directories(device/muon/common/include)
include_directories(device/muon/decoding/include)
include_directories(device/muon/match_upstream_muon/include)
include_directories(device/utils/prefix_sum/include)
include_directories(device/event_model/velo/include)
include_directories(device/event_model/UT/include)
include_directories(device/event_model/SciFi/include)
include_directories(device/event_model/muon/include)
include_directories(device/event_model/common/include)
include_directories(device/vertex_fit/common/include)
include_directories(device/selections/Hlt1/include)
include_directories(device/raw_banks/include)
include_directories(checker/tracking/include)
include_directories(checker/pv/include)
include_directories(checker/selections/include)
include_directories(stream/sequence/include)
include_directories(stream/gear/include)
include_directories(device/UT/UTDecoding/include)
include_directories(device/kalman/ParKalman/include)
include_directories(mdf/include)
include_directories(integration/monitoring/include)
include_directories(integration/non_event_data/include)
include_directories(external)
include_directories(SYSTEM ${ZMQ_INCLUDE_DIRS})
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

#Main Allen executable
file(GLOB common_sources "main/src/*.cpp")
file(GLOB common_device_sources "main/src/*.cu")

#Remove main.cpp from common_sources
foreach(source main Allen AllenThreads OutputHandler ZMQOutputSender MPISend)
  get_filename_component(${source}_cpp_path ${CMAKE_CURRENT_SOURCE_DIR}/main/src/${source}.cpp ABSOLUTE)
  list(REMOVE_ITEM common_sources "${${source}_cpp_path}")
endforeach()

if (USE_MPI AND MPI_FOUND)
  list(APPEND common_sources "main/src/MPISend.cpp")
endif()

#common libraries
allen_add_host_library(Common STATIC ${common_sources})

message(STATUS "CMAKE CXX FLAGS: " ${CMAKE_CXX_FLAGS})

add_library(allen_fs INTERFACE)
find_package(Filesystem)
if(NOT Filesystem_FOUND)
  find_package(Boost COMPONENTS filesystem REQUIRED)
  target_compile_definitions(allen_fs INTERFACE USE_BOOST_FILESYSTEM)
  target_link_libraries(allen_fs INTERFACE Boost::filesystem)
else()
  target_link_libraries(allen_fs INTERFACE std::filesystem)
endif()
target_link_libraries(Common mdf allen_fs nlohmann_json::nlohmann_json)

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  set_source_files_properties(${common_device_sources} PROPERTIES LANGUAGE CXX)
endif()

set(allen_lib_sources ${Allen_cpp_path}
                      ${AllenThreads_cpp_path}
                      ${OutputHandler_cpp_path}
                      ${ZMQOutputSender_cpp_path})

allen_add_device_library(AllenLib SHARED ${allen_lib_sources})

# Required packages
find_package(Threads REQUIRED)

target_link_libraries(AllenLib PUBLIC
  Stream
  Common
  TrackChecking
  PVChecking
  CheckClustering
  SelChecking
  AllenMonitoring
  NonEventData
  AllenZMQ
  Threads::Threads)

if (USE_MPI AND MPI_FOUND)
  get_filename_component(MPI_LIBRARY_DIR ${MPI_mpi_LIBRARY} DIRECTORY)
  target_link_libraries(AllenLib PUBLIC ${MPI_CXX_LIBRARIES})
  if (HWLOC_FOUND)
    target_link_libraries(AllenLib PUBLIC -L${MPI_LIBRARY_DIR} PkgConfig::HWLOC open-pal)
    target_compile_definitions(AllenLib PRIVATE HAVE_HWLOC)
  endif()
endif()

if (USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(AllenLib PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(AllenLib SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  target_link_libraries(AllenLib PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

if (GaudiProject_FOUND)
  find_package(AIDA)
  target_include_directories(AllenLib PUBLIC ${AIDA_INCLUDE_DIRS})
endif()

allen_add_executable(Allen ${main_cpp_path})

if (STANDALONE)
  target_link_libraries(Allen PRIVATE AllenLib)
else()
  find_package(fmt REQUIRED)
  target_link_libraries(Allen PRIVATE AllenLib fmt::fmt)
endif()
