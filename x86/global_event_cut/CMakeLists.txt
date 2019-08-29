file(GLOB cpu_gec "src/*cu")

include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/global_event_cut/include)

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${cpu_gec} PROPERTIES LANGUAGE CXX)
endif()

allen_add_library(CpuGEC STATIC
  ${cpu_gec}
)
