cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

# --------
# Settings
# --------

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX}) # for find_package
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake) # for find_package
set(CUDA_SEPARABLE_COMPILATION ON)
set(CMAKE_CXX_EXTENSIONS OFF) # Generate -std=c++17 instead of -std=gnu++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ---------------
# Boolean options
# ---------------

option(BUILD_TESTS "Build test programs" OFF)
option(USE_ROOT "Build with ROOT" OFF)
option(USE_MPI "Build the MPI sender and enable receiving MEPs over MPI" OFF)
option(USE_LZMA "build with lzma" OFF)
option(USE_LZ4 "build with lz4" OFF)
option(USE_KALMAN_DOUBLE_PRECISION "Use double precision Kalman filter" OFF)
option(CUDA_PROPAGATE_HOST_FLAGS "Propagate CUDA host flags" OFF)
option(CPU_USE_REAL_HALF "Use half_t with uint16_t backend" OFF)

# -----------------------
# Multiple-choice options
# -----------------------

# Device target architecture
set(TARGET_DEVICE CUDA CACHE STRING "Target architecture of the device")
set_property(CACHE TARGET_DEVICE PROPERTY STRINGS CUDA CPU HIP CUDACLANG)

# Build type
set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type")
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS RelWithDebInfo Release Debug)
message(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})

# CUDA compute capability
set(CUDA_ARCH COMPATIBILITY CACHE STRING "CUDA target compute capability")
set_property(CACHE CUDA_ARCH PROPERTY STRINGS COMPATIBILITY MAX MIN 53 60 61 62 70 72 75)

# --------------------
# Unrestricted options
# --------------------

# Configured sequence
set(SEQUENCE DefaultSequence CACHE STRING "Configured sequence")
message(STATUS "Configured sequence: " ${SEQUENCE})

#Configured CPU architecture
set(CPU_ARCH native CACHE STRING "Target CPU architecture")
message(STATUS "CPU_ARCH: " ${CPU_ARCH})

# Deal with device target architecture
if(DEFINED ENV{LHCBRELEASES})
  if(FORCE_CUDA)
    message(STATUS "Using CUDA target for Gaudi build")
  else()
    message(STATUS "Setting CPU target for Gaudi build")
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

#Setup the project to build as a Gaudi project or else standalone
macro(allen_project)
#Gaudi build
  if (DEFINED ENV{LHCBRELEASES})
    find_package(GaudiProject REQUIRED)

#Declare project name and version
    gaudi_project(Allen v0r9 USE Rec HEAD Online HEAD)

#Use the lowest - common - denominator cpu arch
    set(CPU_ARCH "x86-64 -msse4.2")

#Always enable tests for gaudi builds
    set(BUILD_TESTS ON)

#Always enable ROOT for Gaudi builds
    set(USE_ROOT ON)

#Find the CUDA compiler if it's not set
#FIXME : this assumes a standard cuda install : re - evaluate if
#LCG_XXcudaYY is used
    if (TARGET_DEVICE STREQUAL "CUDA")
      if (NOT CMAKE_CUDA_COMPILER)
        find_program(CMAKE_CUDA_COMPILER nvcc
                     HINTS /usr/local/cuda/bin)
        if (CMAKE_CUDA_COMPILER)
          message(STATUS "Found cuda compiler ${CMAKE_CUDA_COMPILER}")
        endif()
      else()
        message(STATUS "Using cuda compiler ${CMAKE_CUDA_COMPILER}")
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
endmacro()

#Setup project for the configured target
if(TARGET_DEVICE STREQUAL "CPU")
  add_compile_definitions(CPU)
  allen_project()

#This seems to be needed across compilers
  add_definitions("-x c++")

  if(CPU_USE_REAL_HALF)
    add_compile_definitions(CPU_USE_REAL_HALF)
  endif()

  function(allen_add_host_library)
    add_library(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  function(allen_add_device_library)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  set(CMAKE_CXX_FLAGS_ADDITIONAL "-Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0)
    set(CMAKE_CXX_FLAGS_ADDITIONAL "${CMAKE_CXX_FLAGS_ADDITIONAL} -Wno-maybe-uninitialized")
  endif()
elseif(TARGET_DEVICE STREQUAL "HIP")
  add_compile_definitions(HIP)

#Setup HIPCC compiler
  if(NOT DEFINED HIP_PATH)
    if(NOT DEFINED ENV{HIP_PATH})
      set(HIP_PATH "/opt/rocm/hip" CACHE PATH "Path to which HIP has been installed")
    else()
      set(HIP_PATH $ENV{HIP_PATH} CACHE PATH "Path to which HIP has been installed")
    endif()
  endif()

#Set linker location
  set(HCC_HOME "${HIP_PATH}/../hcc")
  set(HCC_PATH "${HIP_PATH}/../hcc")

  set(CMAKE_MODULE_PATH "${HIP_PATH}/cmake" ${CMAKE_MODULE_PATH})
  include_directories(${HIP_PATH}/include)
  include_directories(${HIP_PATH}/../hsa/include)

  allen_project()

  find_package(HIP QUIET REQUIRED)
  if(HIP_FOUND)
    message(STATUS "Found HIP: " ${HIP_VERSION})
  else()
    message(FATAL_ERROR "Could not find HIP. Ensure that HIP is either installed in /opt/rocm/hip or the variable HIP_PATH is set.")
  endif()

  set(HIP_SEPARABLE_COMPILATION ON)

  set(CMAKE_CXX_FLAGS_ADDITIONAL "-Wno-unused-result")
elseif(TARGET_DEVICE STREQUAL "CUDACLANG")
  add_compile_definitions(TARGET_DEVICE_CUDACLANG)

  allen_project()

  function(allen_add_host_library)
    add_library(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()
  
  set(cuda_base_dir /usr/local/cuda-10.1)

  function(allen_add_device_library)
    foreach(arg IN LISTS ARGN)
      if(${arg} MATCHES "\\.cu$")
        set_source_files_properties(${arg} PROPERTIES LANGUAGE CXX)
      endif()
    endforeach()

    add_library(${ARGV})
    set_property(TARGET ${ARGV0} PROPERTY LINKER_LANGUAGE CXX)
    target_compile_options(${ARGV0} PRIVATE -x cuda --cuda-path=${cuda_base_dir} -pthread --cuda-gpu-arch=sm_75 -fcuda-rdc --no-cuda-include-ptx=all)
  endfunction()

  function(allen_add_executable)
    message(STATUS "Please use nvcc to link the executable.")
    add_executable(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()
elseif(TARGET_DEVICE STREQUAL "CUDA")
#Workaround 1 / 2 for shared cuda runtime
  set(CMAKE_CUDA_FLAGS "" CACHE STRING "")
  if(CMAKE_CUDA_FLAGS)
	list(REMOVE_ITEM CMAKE_CUDA_FLAGS "-cudart static")
  endif()
  string(APPEND CMAKE_CUDA_FLAGS "-cudart shared --shared --compiler-options -fPIC")

  allen_project()
  enable_language(CUDA)

#Workaround 2 / 2 for shared cuda runtime
  if(CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES)
	list(REMOVE_ITEM CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES "cudart_static")
  endif()
  if(CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES)
	list(REMOVE_ITEM CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES "cudart_static" )
  endif()

  message(STATUS "Detected CUDA include directory: " ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

  function(allen_add_host_library)
    add_library(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES} ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  function(allen_add_device_library)
    add_library(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES} ${CPPGSL_INCLUDE_DIR})
    set_property(TARGET ${ARGV0} PROPERTY CUDA_SEPARABLE_COMPILATION ON)
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    target_include_directories(${ARGV0} PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES} ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  set(CMAKE_CXX_FLAGS_ADDITIONAL "-Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 9.0)
    set(CMAKE_CXX_FLAGS_ADDITIONAL "${CMAKE_CXX_FLAGS_ADDITIONAL} -Wno-maybe-uninitialized")
  endif()
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_CXX_FLAGS_ADDITIONAL "${CMAKE_CXX_FLAGS_ADDITIONAL} -Wno-gnu-zero-variadic-macro-arguments")
endif()

set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_ADDITIONAL} -O3 -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_ADDITIONAL} -O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_ADDITIONAL} -O0 -g -DALLEN_DEBUG")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lpthread")

add_custom_target(configured_sequence DEPENDS "${PROJECT_BINARY_DIR}/configuration/sequences/ConfiguredSequence.h")

#Detect target CPU architecture
include(TargetArch.cmake)
set(TARGET_CPU_ARCHITECTURE "")
target_architecture(TARGET_CPU_ARCHITECTURE)
message(STATUS "Detected CPU architecture: ${TARGET_CPU_ARCHITECTURE}")

#Specific optimizations for different architectures
if(TARGET_CPU_ARCHITECTURE STREQUAL "x86_64" OR TARGET_CPU_ARCHITECTURE STREQUAL "i386"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "ia64")
#x86 family
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH}")
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "ppc" OR TARGET_CPU_ARCHITECTURE STREQUAL "ppc64")
#PowerPC family
#More options on : https: // developer.ibm.com/linuxonpower/compiler-options-table/
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=${CPU_ARCH}")
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "arm" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv5"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "armv6" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv7")
#ARM family
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH}")
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "aarch64")
#ARM64 family
#Options from : http: // www.prace-ri.eu/IMG/pdf/Best-Practice-Guide-ARM64.pdf
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH} -floop-optimize \
-falign-loops -falign-labels -falign-functions -falign-jumps -fomit-frame-pointer")
endif()

if(TARGET_DEVICE STREQUAL "CUDA")
  set(CUDA_SEPARABLE_COMPILATION ON)
  option(CUDA_PROPAGATE_HOST_FLAGS "Propagate CUDA host flags" OFF)
  set(CMAKE_CUDA_STANDARD 14)

#Settings can be overriden by setting OVERRIDE_CUDA_ARCH_FLAG
  if(DEFINED OVERRIDE_CUDA_ARCH_FLAG AND NOT OVERRIDE_CUDA_ARCH_FLAG STREQUAL "")
    message(STATUS "Overriding CUDA architecture setting.")
    set(ARCH_FLAG "${OVERRIDE_CUDA_ARCH_FLAG}")
#CUDA_ARCH can be set to MAX
  elseif(CUDA_ARCH STREQUAL "MAX")
    set(OUTPUTFILE ${CMAKE_BINARY_DIR}/cuda_arch) # No suffix required
    set(CUDAFILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/cuda_arch.cu)
    execute_process(COMMAND ${CMAKE_CUDA_COMPILER} -ccbin=${CMAKE_CXX_COMPILER} -std=c++14 -lcuda ${CUDAFILE} -o ${OUTPUTFILE})
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
      set(ARCH_FLAG "-gencode=arch=compute_${CUDA_ARCH_OUTPUT},code=sm_${CUDA_ARCH_OUTPUT}")
    endif()
#CUDA_ARCH can be set to MIN
  elseif(CUDA_ARCH STREQUAL "MIN")
    message(STATUS "Setting lowest CUDA compute capability:")
    set(ARCH_FLAG "-gencode=arch=compute_53,code=compute_53")
#By default, compile for compatibility
  elseif(CUDA_ARCH STREQUAL "COMPATIBILITY")
#Compatibility arch flag.
#* These settings support natively archs 3.0, 5.0, 6.0, 7.0 and 7.5.
#* All other 3.X, 5.X and 6.X architectures are supported through their respective
#major number builds, specifics of those architectures are not used.
#* Forward compatibility with newer devices is also supported by generating PTX from 7.5
#(- gencode = arch = compute_75, compute = compute_75)
    message(STATUS "Setting compute capability to COMPATIBILITY:")
    foreach(arch 53 60 70 75)
      set(COMPATIBILITY_CUDA_ARCH_FLAG "${COMPATIBILITY_CUDA_ARCH_FLAG} -gencode=arch=compute_${arch},code=sm_${arch}")
    endforeach()
    set(COMPATIBILITY_CUDA_ARCH_FLAG "${COMPATIBILITY_CUDA_ARCH_FLAG} -gencode=arch=compute_75,code=compute_75")
    set(ARCH_FLAG "${COMPATIBILITY_CUDA_ARCH_FLAG}")
#Finally, compile for the specified architecture
  else()
    message(STATUS "Setting architecture " ${CUDA_ARCH})
    set(ARCH_FLAG "-gencode=arch=compute_${CUDA_ARCH},code=sm_${CUDA_ARCH}")
  endif()
  message(STATUS "Cuda architecture set to ${ARCH_FLAG}")

  if(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG --generate-line-info")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set(CMAKE_CUDA_FLAGS_RELEASE "-O3 -DNDEBUG --generate-line-info")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    set(CMAKE_CUDA_FLAGS_DEBUG "-O0 -G -g -DALLEN_DEBUG ")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif()

  option(CUDA_VEBOSE_BUILD "CUDA verbose build" OFF)
  if (CUDA_VERBOSE_BUILD)
    set(CUDA_VERBOSE_FLAGS "--resource-usage --verbose --nvlink-options=--verbose -Xptxas=--verbose")
  else()
    set(CUDA_VERBOSE_FLAGS "")
  endif()

  string(APPEND CMAKE_CUDA_FLAGS " ${ARCH_FLAG} --ftemplate-depth=500 --use_fast_math --expt-relaxed-constexpr ${CUDA_VERBOSE_FLAGS}")

elseif(TARGET_DEVICE STREQUAL "HIP")
#HCC Options(HIPCC compiler)
#Other warning options : -Wall - Wno - bitwise - op - parentheses - Wno - unused - variable - Wno - logical - op - \parentheses
  if(${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
    set(HIP_RELEASE_OPTIONS "-O3 -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
#Note : HIP does not support asserts for now
    message(STATUS "HIP Debug: Asserts not supported yet, setting -DNDEBUG")
    set(HIP_RELEASE_OPTIONS "-g -DNDEBUG")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif()

#Other options tested:
#- hc - hc - function - calls
#- finline - functions - finline - hint - functions
#- flto - fwhole - program - vtables
#- funroll - loops
#- fstack - protector - strong
#- fPIC - shared
  set(HIPCC_OPTIONS "${HIP_RELEASE_OPTIONS} -std=c++17 -Wno-unused-result -Wno-invalid-noreturn")

  function(allen_add_host_library)
    add_library(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

#Define allen_add_device_library and allen_add_executable HIP specializations
  function(allen_add_device_library)
    hip_add_library(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    set_property(TARGET ${ARGV0} PROPERTY
      HIP_SEPARABLE_COMPILATION ON)
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    hip_add_executable(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    set_target_properties(${ARGV0}
         PROPERTIES HIP_SEPARABLE_COMPILATION ON
                  HIP_RESOLVE_DEVICE_SYMBOLS ON)
    target_include_directories(${ARGV0} PUBLIC ${CPPGSL_INCLUDE_DIR})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()
endif()

find_package(ZLIB REQUIRED)

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

if(USE_LZMA)
  find_package(LibLZMA REQUIRED)
else(USE_LZMA)
  set(LZMA_FOUND OFF)
endif(USE_LZMA)

if(USE_LZ4)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(LZ4 REQUIRED liblz4)
else(USE_LZ4)
  set(LZ4_FOUND OFF)
endif(USE_LZ4)

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

add_subdirectory(cuda)
add_subdirectory(stream)
add_subdirectory(checker)
add_subdirectory(x86/global_event_cut)
add_subdirectory(x86/velo/clustering)
add_subdirectory(x86/prefix_sum)
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
include_directories(x86/velo/clustering/include)
include_directories(x86/utils/prefix_sum/include)
include_directories(cuda/global_event_cut/include)
include_directories(cuda/UT/common/include)
include_directories(cuda/UT/compassUT/include)
include_directories(cuda/UT/UTDecoding/include)
include_directories(cuda/UT/consolidate/include)
include_directories(cuda/velo/common/include)
include_directories(cuda/velo/calculate_phi_and_sort/include)
include_directories(cuda/velo/consolidate_tracks/include)
include_directories(cuda/velo/mask_clustering/include)
include_directories(cuda/velo/search_by_triplet/include)
include_directories(cuda/velo/simplified_kalman_filter/include)
include_directories(cuda/PV/common/include)
include_directories(cuda/PV/beamlinePV/include)
include_directories(cuda/SciFi/common/include)
include_directories(cuda/SciFi/looking_forward/search_initial_windows/include)
include_directories(cuda/SciFi/looking_forward/collect_candidates/include)
include_directories(cuda/SciFi/looking_forward/triplet_seeding/include)
include_directories(cuda/SciFi/looking_forward/triplet_keep_best/include)
include_directories(cuda/SciFi/looking_forward/extend_tracks_x/include)
include_directories(cuda/SciFi/looking_forward/extend_missing_x/include)
include_directories(cuda/SciFi/looking_forward/composite_algorithms/include)
include_directories(cuda/SciFi/looking_forward/extend_tracks_uv/include)
include_directories(cuda/SciFi/looking_forward/quality_filter/include)
include_directories(cuda/SciFi/looking_forward/quality_filter_x/include)
include_directories(cuda/SciFi/looking_forward/search_uv_windows/include)
include_directories(cuda/SciFi/looking_forward/common/include)
include_directories(cuda/SciFi/classifiers/include)
include_directories(cuda/SciFi/consolidate/include)
include_directories(cuda/muon/common/include)
include_directories(cuda/muon/decoding/include)
include_directories(cuda/muon/match_upstream_muon/include)
include_directories(cuda/utils/prefix_sum/include)
include_directories(cuda/event_model/velo/include)
include_directories(cuda/event_model/UT/include)
include_directories(cuda/event_model/SciFi/include)
include_directories(cuda/event_model/common/include)
include_directories(cuda/vertex_fit/common/include)
include_directories(cuda/selections/Hlt1/include)
include_directories(cuda/raw_banks/include)
include_directories(checker/tracking/include)
include_directories(checker/pv/include)
include_directories(checker/selections/include)
include_directories(stream/sequence/include)
include_directories(stream/gear/include)
include_directories(cuda/UT/UTDecoding/include)
include_directories(cuda/kalman/ParKalman/include)
include_directories(mdf/include)
include_directories(integration/monitoring/include)
include_directories(integration/non_event_data/include)
include_directories(SYSTEM ${ZMQ_INCLUDE_DIRS})
include_directories(${CPPGSL_INCLUDE_DIR})

#Main Allen executable
file(GLOB common_sources "main/src/*.cpp")
file(GLOB common_cuda_sources "main/src/*.cu")

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

add_library(allen_fs INTERFACE)
if(APPLE OR (CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.0))
  find_package(Boost COMPONENTS filesystem)
  target_compile_definitions(allen_fs INTERFACE USE_BOOST_FILESYSTEM)
  target_link_libraries(allen_fs INTERFACE Boost::filesystem)
else()
  find_package(Filesystem)
  target_link_libraries(allen_fs INTERFACE std::filesystem)
endif()
target_link_libraries(Common mdf allen_fs)

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  set_source_files_properties(${common_cuda_sources} PROPERTIES LANGUAGE CXX)
endif()

allen_add_device_library(CudaCommon STATIC ${common_cuda_sources})

set(allen_lib_sources ${Allen_cpp_path}
                      ${AllenThreads_cpp_path}
                      ${OutputHandler_cpp_path}
                      ${ZMQOutputSender_cpp_path})

if(TARGET_DEVICE STREQUAL "HIP" OR TARGET_DEVICE STREQUAL "CUDACLANG")
#Produce self - contained application
#Otherwise, HIP doesn't seem to link properly
  allen_add_device_library(AllenLib STATIC ${allen_lib_sources})
else()
#Library containing all the code
  allen_add_device_library(AllenLib SHARED ${allen_lib_sources})
endif()

target_link_libraries(AllenLib PUBLIC
  Stream
  Common
  CudaCommon
  TrackChecking
  PVChecking
  CheckClustering
  SelChecking
  AllenMonitoring
  NonEventData
  AllenZMQ)

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
target_link_libraries(Allen PRIVATE AllenLib)
