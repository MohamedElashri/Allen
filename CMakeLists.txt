cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

# Determine whether to produce a CPU version
option(TARGET_CPU "Produce a CPU version" OFF)
option(TARGET_HIP "Produce a HIP version" OFF)
if(DEFINED ENV{LHCBRELEASES})
  message(STATUS "Forcing CPU target for Gaudi build")
  set(TARGET_DEVICE "CPU")
elseif(TARGET_CPU)
  set(TARGET_DEVICE "CPU")
elseif(TARGET_HIP)
  # Note: HIP with nvcc backend is not supported
  #       Instead, compile with CUDA target
  if(HIP_PLATFORM STREQUAL "nvcc")
    message(STATUS "HIP with nvcc backend is not supported (HIP_PLATFORM=nvcc)")
    message(STATUS "Please unset HIP_PLATFORM to trigger a HIP compilation")
    message(STATUS "Continuing with CUDA backend")
    set(TARGET_DEVICE "CUDA")
  else()
    set(TARGET_DEVICE "HIP")
  endif()
else()
  set(TARGET_DEVICE "CUDA")
endif()
message(STATUS "Allen target: ${TARGET_DEVICE}")

# Determine whether to use Tensor Cores
# Note: Tensor cores are only supported in CUDA
option(USE_TENSOR_CORES "Produce CUDA code with Tensor Cores enabled if available" OFF)
if(TARGET_DEVICE STREQUAL "CUDA" AND TENSOR)
  message(STATUS "Tensor core compilation enabled")
  add_compile_definitions(TENSOR_CORES_ENABLED)
endif()

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX}) # for find_package
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake) # for find_package

option(BUILD_TESTS "Build test programs" OFF)

# Setup the project to build as a Gaudi project or else standalone
macro(allen_project)
  # Gaudi build
  if (DEFINED ENV{LHCBRELEASES})
	find_package(GaudiProject REQUIRED)
    # Declare project name and version
    gaudi_project(Allen v0r7
      USE Rec HEAD Online HEAD)

    # Use the lowest-common-denominator cpu arch
    set(CPU_ARCH "x86-64 -msse4.2")

    # Always enable tests for gaudi builds
    set(BUILD_TESTS ON)

    # Find the CUDA compiler if it's not set
    # FIXME: this assumes a standard cuda install: re-evaluate if
    # LCG_XXcudaYY is used
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
      # Make sure the lcg compiler wrapper scripts are used to call
      # the host compiler
      set(CMAKE_CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})

      # Build for maximum compatibility as the build host is different
      # from the the machine running it and may not even have a GPU
      foreach(arch 30 52 61 70 75)
        set(OVERRIDE_ARCH_FLAG "${OVERRIDE_ARCH_FLAG} -gencode arch=compute_${arch},code=sm_${arch}")
      endforeach()
    endif()

  else()
    project(Allen C CXX)
    if (BUILD_TESTS)
      enable_testing()
    endif()
  endif()
endmacro()

# Setup project for the configured target
if(TARGET_DEVICE STREQUAL "CPU")
  allen_project()
  add_compile_definitions(CPU)

  # This seems to be needed across compilers
  add_definitions("-x c++")

  function(allen_add_library)
    add_library(${ARGV})
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  set(CMAKE_CXX_FLAGS_ADDITIONAL "-Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.0)
    set(CMAKE_CXX_FLAGS_ADDITIONAL "${CMAKE_CXX_FLAGS_ADDITIONAL} -Wno-maybe-uninitialized")
  endif()
elseif(TARGET_DEVICE STREQUAL "HIP")
  add_compile_definitions(HIP)

  # Setup HIPCC compiler
  if(NOT DEFINED HIP_PATH)
    if(NOT DEFINED ENV{HIP_PATH})
      set(HIP_PATH "/opt/rocm/hip" CACHE PATH "Path to which HIP has been installed")
    else()
      set(HIP_PATH $ENV{HIP_PATH} CACHE PATH "Path to which HIP has been installed")
    endif()
  endif()

  # Set linker location
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
else()
  # Workaround 1/2 for shared cuda runtime
  set(CMAKE_CUDA_FLAGS "" CACHE STRING "")
  if(CMAKE_CUDA_FLAGS)
	list(REMOVE_ITEM CMAKE_CUDA_FLAGS "-cudart static")
  endif()
  string(APPEND CMAKE_CUDA_FLAGS "-cudart shared")

  allen_project()
  enable_language(CUDA)

  # Workaround 2/2 for shared cuda runtime
  if(CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES)
	list(REMOVE_ITEM CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES "cudart_static")
  endif()
  if(CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES)
	list(REMOVE_ITEM CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES "cudart_static" )
  endif()

  # Determine whether to use Tensor Cores
  # Note: Tensor cores are only supported in CUDA
  option(TENSOR "Produce CUDA code with Tensor Cores enabled if available" OFF)
  if(TARGET_DEVICE STREQUAL "CUDA" AND TENSOR)
	add_compile_definitions(TENSOR_CORES_ENABLED)
  endif()

  function(allen_add_library)
    add_library(${ARGV})
    set_property(TARGET ${ARGV0} PROPERTY
      CUDA_SEPARABLE_COMPILATION ON)
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    add_executable(${ARGV})
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()

  set(CMAKE_CXX_FLAGS_ADDITIONAL "-Wall -Wextra -Wpedantic -Wnon-virtual-dtor -Wdouble-promotion")

  if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 9.0)
    set(CMAKE_CXX_FLAGS_ADDITIONAL "${CMAKE_CXX_FLAGS_ADDITIONAL} -Wno-maybe-uninitialized")
  endif()
endif()

# Deal with build type
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif(NOT CMAKE_BUILD_TYPE)
MESSAGE(STATUS "CMAKE_BUILD_TYPE: " ${CMAKE_BUILD_TYPE})

# Configured sequence
if(NOT SEQUENCE)
  set(SEQUENCE DefaultSequence)
endif(NOT SEQUENCE)

if(NOT DEFINED CPU_ARCH)
  set(CPU_ARCH native)
endif()

# Detect target CPU architecture
include(TargetArch.cmake)
SET(TARGET_CPU_ARCHITECTURE "")
target_architecture(TARGET_CPU_ARCHITECTURE)
MESSAGE(STATUS "Detected CPU architecture: ${TARGET_CPU_ARCHITECTURE}")

# Specific optimizations for different architectures
if(TARGET_CPU_ARCHITECTURE STREQUAL "x86_64" OR TARGET_CPU_ARCHITECTURE STREQUAL "i386"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "ia64")
  # x86 family
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH}")
  MESSAGE(STATUS "CPU_ARCH: " ${CPU_ARCH})
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "ppc" OR TARGET_CPU_ARCHITECTURE STREQUAL "ppc64")
  # PowerPC family
  # More options on: https://developer.ibm.com/linuxonpower/compiler-options-table/
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=${CPU_ARCH}")
  MESSAGE(STATUS "CPU_ARCH: " ${CPU_ARCH})
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "arm" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv5"
  OR TARGET_CPU_ARCHITECTURE STREQUAL "armv6" OR TARGET_CPU_ARCHITECTURE STREQUAL "armv7")
  # ARM family
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH}")
  MESSAGE(STATUS "CPU_ARCH: " ${CPU_ARCH})
elseif(TARGET_CPU_ARCHITECTURE STREQUAL "aarch64")
  # ARM64 family
  # Options from: http://www.prace-ri.eu/IMG/pdf/Best-Practice-Guide-ARM64.pdf
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH} -floop-optimize \
-falign-loops -falign-labels -falign-functions -falign-jumps -fomit-frame-pointer")
  MESSAGE(STATUS "CPU_ARCH: " ${CPU_ARCH})
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_ADDITIONAL} -O3 -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_ADDITIONAL} -O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_ADDITIONAL} -O0 -g -DDEBUG")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lpthread")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(TARGET_DEVICE STREQUAL "CUDA")
  set(CUDA_SEPARABLE_COMPILATION ON)
  option(CUDA_PROPAGATE_HOST_FLAGS "Propagate CUDA host flags" OFF)
  set(CMAKE_CUDA_STANDARD 14)

  # Configuration of CUDA compute architecture
  if(NOT DEFINED CUDA_ARCH)
    set(CUDA_ARCH "MAX" CACHE STRING "Cuda architecture")
  endif()

  if(DEFINED OVERRIDE_ARCH_FLAG)
    message(STATUS "Cuda architecture set to ${OVERRIDE_ARCH_FLAG}")
    set(ARCH_FLAG ${OVERRIDE_ARCH_FLAG})
  elseif (CUDA_ARCH STREQUAL "MIN" OR CUDA_ARCH STREQUAL "MAX" OR CUDA_ARCH STREQUAL "COMP")
    set(OUTPUTFILE ${CMAKE_BINARY_DIR}/cuda_arch) # No suffix required
    set(CUDAFILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/cuda_arch.cu)
    execute_process(COMMAND ${CMAKE_CUDA_COMPILER} -ccbin=${CMAKE_CXX_COMPILER} -std=c++14 -lcuda ${CUDAFILE} -o ${OUTPUTFILE})
    if(CUDA_ARCH STREQUAL "MAX")
      set(CHECK_ARGS "-l")
    endif()
    message(STATUS "Detecting ${CUDA_ARCH} CUDA architecture")
    execute_process(COMMAND ${OUTPUTFILE} ${CHECK_ARGS}
      RESULT_VARIABLE CUDA_RETURN_CODE
      OUTPUT_VARIABLE CUDA_ARCH_OUTPUT)

    if(${CUDA_RETURN_CODE} EQUAL 1)
      message(FATAL_ERROR "${CUDA_ARCH}")
    else()
      if (CUDA_ARCH STREQUAL "MIN")
        message(STATUS "Detecting ${CUDA_ARCH} CUDA architecture - sm_30")
        set(ARCH_FLAG "-arch=sm_30")
      else()
        message(STATUS "Detecting ${CUDA_ARCH} CUDA architecture - ${CUDA_ARCH_OUTPUT}")
        set(ARCH_FLAG "-arch=${CUDA_ARCH_OUTPUT}")
      endif()
    endif()
  else()
    message(STATUS "Cuda architecture manually set to ${CUDA_ARCH}")
    set(ARCH_FLAG "-arch=${CUDA_ARCH}")
  endif()

  # Cuda: Deal with build type
  if(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
    set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG --generate-line-info")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL Release)
    set(CMAKE_CUDA_FLAGS_RELEASE "-O3 -DNDEBUG --generate-line-info")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL Debug)
    set(CMAKE_CUDA_FLAGS_DEBUG "-O0 -G -g -DDEBUG ")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)

  option(CUDA_VEBOSE_BUILD "CUDA verbose build" OFF)
  if (CUDA_VERBOSE_BUILD)
    set(CUDA_VERBOSE_FLAGS "--resource-usage --verbose --nvlink-options=--verbose -Xptxas=--verbose")
  else()
    set(CUDA_VERBOSE_FLAGS "")
  endif()

  set(CMAKE_CUDA_FLAGS " ${ARCH_FLAG} --ftemplate-depth=300 --use_fast_math --expt-relaxed-constexpr ${CUDA_VERBOSE_FLAGS}")

elseif(TARGET_DEVICE STREQUAL "HIP")
  # HCC Options (HIPCC compiler)
  # Other warning options: -Wall -Wno-bitwise-op-parentheses -Wno-unused-variable -Wno-logical-op-parentheses
  if(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
    set(HIP_RELEASE_OPTIONS "-O3 -g -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL Release)
    set(HIP_RELEASE_OPTIONS "-O3 -DNDEBUG")
  elseif(${CMAKE_BUILD_TYPE} STREQUAL Debug)
    # Note: HIP does not support asserts for now
    message(STATUS "HIP Debug: Asserts not supported yet, setting -DNDEBUG")
    set(HIP_RELEASE_OPTIONS "-g -DNDEBUG")
  else()
    message(FATAL_ERROR "Build type ${CMAKE_BUILD_TYPE} is unknown. Use RelWithDebInfo, Release or Debug.")
  endif(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)

  # Other options tested:
  # -hc -hc-function-calls
  # -finline-functions -finline-hint-functions
  # -flto -fwhole-program-vtables
  # -funroll-loops
  # -fstack-protector-strong
  # -fPIC -shared
  set(HIPCC_OPTIONS "${HIP_RELEASE_OPTIONS} -std=c++17 -Wno-unused-result -Wno-invalid-noreturn")

  # Define allen_add_library and allen_add_executable HIP specializations
  function(allen_add_library)
    hip_add_library(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    set_property(TARGET ${ARGV0} PROPERTY
      HIP_SEPARABLE_COMPILATION ON)
    install(TARGETS ${ARGV0} DESTINATION lib OPTIONAL)
  endfunction()

  function(allen_add_executable)
    hip_add_executable(${ARGV} HIPCC_OPTIONS ${HIPCC_OPTIONS})
    set_target_properties(${ARGV0}
         PROPERTIES HIP_SEPARABLE_COMPILATION ON
                  HIP_RESOLVE_DEVICE_SYMBOLS ON)
    install(TARGETS ${ARGV0} RUNTIME DESTINATION bin OPTIONAL)
  endfunction()
endif()

find_package(ZLIB REQUIRED)
find_package(MPI REQUIRED)

option(USE_LZMA "build with lzma" OFF)
if(USE_LZMA)
  find_package(LibLZMA REQUIRED)
else(USE_LZMA)
  set(LZMA_FOUND OFF)
endif(USE_LZMA)

option(USE_LZ4 "build with lz4" OFF)
if(USE_LZ4)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(LZ4 REQUIRED liblz4)
else(USE_LZ4)
  set(LZ4_FOUND OFF)
endif(USE_LZ4)

option(USE_KALMAN_DOUBLE_PRECISION "Use double precision Kalman filter" OFF)
if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()

set(CUDA_SEPARABLE_COMPILATION ON)
option(CUDA_PROPAGATE_HOST_FLAGS "Propagate CUDA host flags" OFF)

option(USE_ROOT "Build with ROOT" OFF)
if ((EXISTS $ENV{ROOTSYS}) AND (USE_ROOT))
   if(EXISTS $ENV{ROOTSYS}/cmake/ROOTConfig.cmake) # ROOT was compiled with cmake
     set(ALLEN_ROOT_CMAKE $ENV{ROOTSYS})
   else() # ROOT was compiled with configure/make
     set(ALLEN_ROOT_CMAKE $ENV{ROOTSYS}/etc)
   endif()
   find_package(ROOT QUIET HINTS ${ALLEN_ROOT_CMAKE} NO_DEFAULT_PATH COMPONENTS Core Hist Tree)
   if (ROOT_FOUND)
      message(STATUS "Compiling with ROOT: " ${ROOT_INCLUDE_DIRS})

      # If ROOT is built with C++17 support, everything that includes ROOT
      # headers must be built with C++17 support. CUDA doesn't support
      # that, so we have to factor that out.
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
else()
   message(STATUS "Compiling without ROOT")
endif()

set(EXTERNAL_DIR "external")

add_subdirectory(cuda)
add_subdirectory(stream)
add_subdirectory(checker)
add_subdirectory(x86/velo/clustering)
add_subdirectory(x86/utils)
add_subdirectory(x86/global_event_cut)
add_subdirectory(mdf)
add_subdirectory(integration)
add_subdirectory(zmq)

# Include directories
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(main/include)
include_directories(x86/velo/clustering/include)
include_directories(x86/global_event_cut/include)
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
include_directories(cuda/SciFi/classifiers/include)
include_directories(cuda/SciFi/consolidate/include)
include_directories(cuda/muon/common/include)
include_directories(cuda/utils/prefix_sum/include)
include_directories(cuda/event_model/velo/include)
include_directories(cuda/event_model/UT/include)
include_directories(cuda/event_model/SciFi/include)
include_directories(cuda/event_model/common/include)
include_directories(checker/tracking/include)
include_directories(checker/pv/include)
include_directories(checker/selections/include)
include_directories(stream/sequence/include)
include_directories(cuda/UT/UTDecoding/include)
include_directories(cuda/kalman/ParKalman/include)
include_directories(mdf/include)
include_directories(integration/non_event_data/include)
include_directories(${ZMQ_INCLUDE_DIRS})
include_directories(${MPI_C_INCLUDE_PATH})

# Main Allen executable
file(GLOB common_sources "main/src/*.cpp")
file(GLOB common_cuda_sources "main/src/*.cu")

# Remove main.cpp from common_sources
foreach(source main Allen)
  get_filename_component(${source}_cpp_path ${CMAKE_CURRENT_SOURCE_DIR}/main/src/${source}.cpp ABSOLUTE)
  list(REMOVE_ITEM common_sources "${${source}_cpp_path}")
endforeach()

# common libraries
add_library(Common STATIC ${common_sources})

if(APPLE)
  find_package(Boost COMPONENTS filesystem)
  target_include_directories(Common SYSTEM PUBLIC ${Boost_INCLUDE_DIR})
  target_link_libraries(Common mdf ${Boost_LIBRARIES})
else()
  target_link_libraries(Common mdf stdc++fs)
endif()

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${common_cuda_sources} PROPERTIES LANGUAGE CXX)
endif()

allen_add_library(CudaCommon STATIC ${common_cuda_sources})

if(TARGET_DEVICE STREQUAL "HIP")
  # Produce self-contained application
  # Otherwise, HIP doesn't seem to link properly
  allen_add_library(AllenLib STATIC ${Allen_cpp_path})
else()
  # Library containing all the code
  allen_add_library(AllenLib SHARED ${Allen_cpp_path})
endif()

target_link_libraries(AllenLib PUBLIC
  Stream
  Common
  TrackChecking
  PVChecking
  CheckClustering
  SelChecking
  NonEventData
  AllenZMQ
  ${MPI_CXX_LIBRARIES})

if (ROOT_FOUND)
  target_compile_definitions(AllenLib PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(AllenLib SYSTEM PUBLIC ${ROOT_INCLUDE_DIRS})
  target_link_libraries(AllenLib PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()

allen_add_executable(Allen ${main_cpp_path})
target_link_libraries(Allen PRIVATE AllenLib)
