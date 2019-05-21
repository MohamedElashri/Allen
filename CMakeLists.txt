cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

# Workaround 1/2 for shared cuda runtime
set(CMAKE_CUDA_FLAGS "" CACHE STRING "")
if (CMAKE_CUDA_FLAGS)
	list(REMOVE_ITEM CMAKE_CUDA_FLAGS "-cudart static")
endif()
string(APPEND CMAKE_CUDA_FLAGS "-cudart shared")

project(Allen C CXX CUDA)

# Workaround 2/2 for shared cuda runtime
if (CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES)
  list(REMOVE_ITEM CMAKE_CUDA_HOST_IMPLICIT_LINK_LIBRARIES "cudart_static")
endif()
if (CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES)
  list(REMOVE_ITEM CMAKE_CUDA_IMPLICIT_LINK_LIBRARIES "cudart_static" )
endif()

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX}) # for find_package
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake) # for find_package

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
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${CPU_ARCH}")
MESSAGE(STATUS "CPU_ARCH: " ${CPU_ARCH})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -DDEBUG")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lpthread")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Configuration of CUDA compute architecture
if(NOT DEFINED CUDA_ARCH)
  set(CUDA_ARCH "MAX" CACHE STRING "Cuda architecture")
endif()

if (CUDA_ARCH STREQUAL "MIN" OR CUDA_ARCH STREQUAL "MAX" OR CUDA_ARCH STREQUAL "COMP")
  set(OUTPUTFILE ${PROJECT_BINARY_DIR}/cuda_arch) # No suffix required
  set(CUDAFILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils/cuda_arch.cu)
  execute_process(COMMAND ${CMAKE_CUDA_COMPILER} -lcuda ${CUDAFILE} -o ${OUTPUTFILE})
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
if(DEFINED OVERRIDE_ARCH_FLAG)
  set(ARCH_FLAG ${OVERRIDE_ARCH_FLAG})
endif()

find_package(ZLIB REQUIRED)

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

option(USE_KALMAN_SINGLE_PRECISION "Use single precision Kalman filter" ON)

# find_package(CUDA REQUIRED)
#set(CUDA_HOST_COMPILER "g++")
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
   if ( ROOT_FOUND )
      message(STATUS "Compiling with ROOT: " ${ROOT_INCLUDE_DIRS})

      # If ROOT is built with C++17 support, everything that includes ROOT
      # headers must be built with C++17 support. CUDA doesn't support
      # that, so we have to factor that out.
      execute_process(COMMAND root-config --has-cxx17 OUTPUT_VARIABLE ROOT_HAS_CXX17 ERROR_QUIET)
      string(REGEX REPLACE "\n$" "" ROOT_HAS_CXX17 "${ROOT_HAS_CXX17}")
      message(STATUS "ROOT built with c++17: ${ROOT_HAS_CXX17}")
      if (${ROOT_HAS_CXX17} STREQUAL "yes")
        set(ALLEN_ROOT_DEFINITIONS WITH_ROOT ROOT_CXX17)
      else()
        set(ALLEN_ROOT_DEFINITIONS WITH_ROOT)
      endif()

      set(ALLEN_ROOT_LIBRARIES -L$ENV{ROOTSYS}/lib -lTree -lCore -lCling -lHist)

      execute_process(COMMAND root-config --has-imt OUTPUT_VARIABLE ROOT_HAS_IMT ERROR_QUIET)
      string(REGEX REPLACE "\n$" "" ROOT_HAS_IMT "${ROOT_HAS_IMT}")
      message(STATUS "ROOT built with implicit multi-threading: ${ROOT_HAS_IMT}")
      if (${ROOT_HAS_IMT} STREQUAL "yes")
        find_package(TBB REQUIRED)
        get_filename_component(TBB_LIBDIR ${TBB_LIBRARIES} DIRECTORY)
        #set(ALLEN_ROOT_LIBRARIES -L${TBB_LIBDIR} -ltbb ${ALLEN_ROOT_LIBRARIES})
        set(ALLEN_ROOT_LIBRARIES ${ALLEN_ROOT_LIBRARIES} -L${TBB_LIBDIR} -ltbb)
      endif()
    else()
      message(STATUS "Compiling without ROOT")
   endif()
else()
   message(STATUS "Compiling without ROOT")
endif()

# Cuda: Deal with build type
if(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
  set(CMAKE_CUDA_FLAGS_RELWITHDEBINFO "-O3 -g -DNDEBUG --generate-line-info")
elseif(${CMAKE_BUILD_TYPE} STREQUAL Release)
  set(CMAKE_CUDA_FLAGS_RELEASE "-O3 -DNDEBUG --generate-line-info")
elseif(${CMAKE_BUILD_TYPE} STREQUAL Debug)
  set(CMAKE_CUDA_FLAGS_DEBUG "-O0 -G -g -DDEBUG ")
endif(${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)

option(CUDA_VEBOSE_BUILD "CUDA verbose build" OFF)
if (CUDA_VERBOSE_BUILD)
  set(CUDA_VERBOSE_FLAGS "--resource-usage --verbose --nvlink-options=--verbose -Xptxas=--verbose")
else()
  set(CUDA_VERBOSE_FLAGS "")
endif()
# In case we want to compile with clang:
# --compiler-bindir /cvmfs/sft.cern.ch/lcg/releases/clang/6.0.0-6647e/x86_64-centos7-gcc62-opt/bin/clang++;
set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_FLAGS " ${ARCH_FLAG} --use_fast_math --expt-relaxed-constexpr ${CUDA_VERBOSE_FLAGS}")

add_subdirectory(cuda)
add_subdirectory(stream)
add_subdirectory(checker)
add_subdirectory(x86/UT/PrVeloUT)
add_subdirectory(x86/SciFi)
add_subdirectory(x86/velo/clustering)
add_subdirectory(x86/PV/beamlinePV)
add_subdirectory(x86/muon/decoding)
add_subdirectory(x86/utils)
add_subdirectory(x86/global_event_cut)
add_subdirectory(mdf)
add_subdirectory(integration)

# Include directories
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(main/include)
include_directories(x86/muon/decoding/include)
include_directories(x86/velo/clustering/include)
include_directories(x86/global_event_cut/include)
include_directories(x86/utils/prefix_sum/include)
include_directories(cuda/global_event_cut/include)
include_directories(cuda/UT/common/include)
include_directories(cuda/UT/PrVeloUT/include)
include_directories(cuda/UT/compassUT/include)
include_directories(cuda/UT/UTDecoding/include)
include_directories(cuda/UT/consolidate/include)
include_directories(cuda/velo/common/include)
include_directories(cuda/velo/calculate_phi_and_sort/include)
include_directories(cuda/velo/consolidate_tracks/include)
include_directories(cuda/velo/mask_clustering/include)
include_directories(cuda/velo/search_by_triplet/include)
include_directories(cuda/velo/simplified_kalman_filter/include)
include_directories(cuda/SciFi/common/include)
include_directories(cuda/SciFi/looking_forward/common/include)
include_directories(cuda/SciFi/looking_forward/calculate_first_layer_window/include)
include_directories(cuda/SciFi/looking_forward/calculate_second_layer_window/include)
include_directories(cuda/SciFi/looking_forward/form_seeds_from_candidates/include)
include_directories(cuda/SciFi/looking_forward/calculate_candidate_extrapolation_window/include)
include_directories(cuda/SciFi/looking_forward/promote_candidates/include)
include_directories(cuda/SciFi/looking_forward/calculate_track_extrapolation_window/include)
include_directories(cuda/SciFi/looking_forward/extend_tracks/include)
include_directories(cuda/SciFi/looking_forward_sbt/search_initial_windows/include)
include_directories(cuda/SciFi/looking_forward_sbt/collect_candidates/include)
include_directories(cuda/SciFi/looking_forward_sbt/triplet_seeding/include)
include_directories(cuda/SciFi/looking_forward_sbt/triplet_keep_best/include)
include_directories(cuda/SciFi/looking_forward_sbt/extend_tracks_x/include)
include_directories(cuda/SciFi/looking_forward_sbt/composite_algorithms/include)
include_directories(cuda/SciFi/looking_forward_sbt/extend_tracks_uv/include)
include_directories(cuda/SciFi/looking_forward_sbt/quality_filter/include)
include_directories(cuda/SciFi/looking_forward_sbt/quality_filter_x/include)
include_directories(cuda/SciFi/looking_forward_sbt/search_uv_windows/include)
include_directories(cuda/SciFi/PrForward/include)
include_directories(cuda/SciFi/consolidate/include)
include_directories(cuda/muon/common/include)
include_directories(cuda/utils/prefix_sum/include)
include_directories(cuda/event_model/velo/include)
include_directories(cuda/event_model/UT/include)
include_directories(cuda/event_model/SciFi/include)
include_directories(cuda/event_model/common/include)
include_directories(checker/tracking/include)
include_directories(checker/pv/include)
include_directories(stream/sequence/include)
include_directories(x86/SciFi/PrForward/include)
include_directories(x86/SciFi/LookingForward/include)
include_directories(x86/SciFi/MomentumForward/include)
include_directories(cuda/UT/UTDecoding/include)
include_directories(cuda/kalman/ParKalman/include)
include_directories(mdf/include)
include_directories(integration/non_event_data/include)

file(GLOB common_sources "main/src/*")

# Remove main.cpp from common_sources
foreach(source main Allen)
get_filename_component(${source}_cpp_path ${CMAKE_CURRENT_SOURCE_DIR}/main/src/${source}.cpp ABSOLUTE)
list(REMOVE_ITEM common_sources "${${source}_cpp_path}")
endforeach()

# common library
add_library(Common STATIC ${common_sources})
target_link_libraries(Common mdf)

set_property(TARGET Common PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)

# Library containing all the code
add_library(AllenLib SHARED ${Allen_cpp_path})
target_link_libraries(AllenLib PUBLIC
  Stream
  TrackChecking
  PVChecking
  CheckClustering
  x86MuonDecoding
  Common
  NonEventData)
set_property(TARGET AllenLib PROPERTY OUTPUT_NAME "Allen")

if (ROOT_FOUND)
  target_compile_definitions(AllenLib PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_link_libraries(AllenLib PUBLIC ${ALLEN_ROOT_LIBRARIES})
endif()


# Main executable
add_executable(Allen ${main_cpp_path})
target_link_libraries(Allen PRIVATE AllenLib)

option(BUILD_TESTS "Build test programs" OFF)
if(BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif(BUILD_TESTS)
