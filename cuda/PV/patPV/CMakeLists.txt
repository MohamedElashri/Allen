include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/veloUT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CPPGSL_INCLUDE_DIR})

file(GLOB pat_pv "src/*cu")

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  set_source_files_properties(${pat_pv} PROPERTIES LANGUAGE CXX)
endif()

allen_add_device_library(AllenPatPV STATIC
  ${pat_pv}
)
