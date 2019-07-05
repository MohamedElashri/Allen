file(GLOB cpu_gec "src/*cu")

include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/global_event_cut/include)

add_library(CpuGEC STATIC
  ${cpu_gec}
)

set_property(TARGET CpuGEC PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)
