###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
set(backend_sources src/CPUID.cpp)

add_library(AllenRuntime INTERFACE)

if(TARGET_DEVICE STREQUAL "CPU")
  list(APPEND backend_sources src/CPUBackend.cpp)
  list(APPEND backend_sources src/HalfType.cpp)
elseif(TARGET_DEVICE STREQUAL "CUDA" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  list(APPEND backend_sources src/CUDABackend.cpp)
  find_package(CUDAToolkit REQUIRED)
  target_link_libraries(AllenRuntime INTERFACE CUDA::cudart)
elseif(TARGET_DEVICE STREQUAL "HIP")
  list(APPEND backend_sources src/HIPBackend.cpp)
  find_package(hip REQUIRED)
  target_link_libraries(AllenRuntime INTERFACE hip::host)
endif()

# Vectorization interface library
add_library(Vectorization INTERFACE)
target_include_directories(Vectorization INTERFACE $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/external>)
install(TARGETS Vectorization EXPORT Allen)

# Target to link to allen backend runtime
install(TARGETS AllenRuntime EXPORT Allen)

# Backend library
allen_add_host_library(Backend STATIC ${backend_sources})
target_link_libraries(Backend PUBLIC Vectorization Gear Common)
target_include_directories(Backend PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

set(BackendHeaders)
foreach(header
    AllenTypeTraits.h
    BackendCommon.h
    BackendCommonInterface.h
    CPUBackend.h
    CPUID.h
    CUDABackend.h
    HIPBackend.h
    PinnedVector.h
    Vector.h)
  list(APPEND BackendHeaders include/${header})
endforeach()

install(FILES ${BackendHeaders}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Backend)
