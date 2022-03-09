###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
set(backend_sources src/CPUID.cpp)

if(TARGET_DEVICE STREQUAL "CPU")
  list(APPEND backend_sources src/CPUBackend.cpp)
  list(APPEND backend_sources src/HalfType.cpp)
elseif(TARGET_DEVICE STREQUAL "CUDA")
  list(APPEND backend_sources src/CUDABackend.cpp)
elseif(TARGET_DEVICE STREQUAL "HIP")
  list(APPEND backend_sources src/HIPBackend.cpp)
endif()

# Backend library
allen_add_host_library(Backend STATIC ${backend_sources})
target_link_libraries(Backend PUBLIC Gear AllenCommon umesimd::umesimd)
target_link_libraries(Backend PRIVATE HostCommon)
target_include_directories(Backend PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/Backend>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_compile_definitions(Backend PUBLIC ${TARGET_DEFINITION})

set(BackendHeaders)
foreach(header
    AllenTypeTraits.h
    BackendCommonInterface.h
    BackendCommon.h
    CPUBackend.h
    CPUID.h
    CUDABackend.h
    HIPBackend.h
    PinnedVector.h
    Vector.h)
  list(APPEND BackendHeaders include/${header})
endforeach()

if(TARGET_DEVICE STREQUAL "CUDA")
  target_link_libraries(Backend PUBLIC CUDA::cudart)
elseif(TARGET_DEVICE STREQUAL "HIP")
  target_link_libraries(Backend PUBLIC ${HIP_RUNTIME_LIB})
endif()

install(FILES ${BackendHeaders}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Backend)
