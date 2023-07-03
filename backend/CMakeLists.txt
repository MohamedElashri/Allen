###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
set(backend_sources src/CPUID.cpp)

add_library(AllenRuntime INTERFACE)
install(TARGETS AllenRuntime EXPORT Allen)

if(TARGET_DEVICE STREQUAL "CPU")
  list(APPEND backend_sources src/CPUBackend.cpp)
  list(APPEND backend_sources src/HalfType.cpp)
elseif(TARGET_DEVICE STREQUAL "CUDA")
  list(APPEND backend_sources src/CUDABackend.cpp)
  target_link_libraries(AllenRuntime INTERFACE CUDA::cudart)
elseif(TARGET_DEVICE STREQUAL "HIP")
  list(APPEND backend_sources src/HIPBackend.cpp)
  target_link_libraries(AllenRuntime INTERFACE ${HIP_RUNTIME_LIB})
  target_include_directories(AllenRuntime INTERFACE ${HIP_PATH}/include ${ROCM_PATH}/hsa/include)
endif()

target_include_directories(AllenRuntime INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/Backend>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_compile_definitions(AllenRuntime INTERFACE ${TARGET_DEFINITION})
target_link_libraries(AllenRuntime INTERFACE umesimd::umesimd)

# Backend library
allen_add_host_library(Backend STATIC ${backend_sources})
target_link_libraries(Backend PUBLIC AllenRuntime Gear AllenCommon)

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

install(FILES ${BackendHeaders}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/Backend)
