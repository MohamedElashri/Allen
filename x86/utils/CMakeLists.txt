file(GLOB cpu_prefix_sum "prefix_sum/src/*cu")

include_directories(prefix_sum/include/)
include_directories(${CMAKE_SOURCE_DIR}/main/include)

if(CPU)
  set_source_files_properties(${cpu_prefix_sum} PROPERTIES LANGUAGE CXX)
endif(CPU)

add_library(CpuUtils STATIC
  ${cpu_prefix_sum}
)

set_property(TARGET CpuUtils PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)
