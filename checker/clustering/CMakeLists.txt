include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/host/velo/clustering/include)

file(GLOB clustering "src/*cpp")
include_directories(include)
allen_add_host_library(CheckClustering STATIC
  ${clustering}
)

target_link_libraries(CheckClustering PRIVATE HostClustering)
target_include_directories(CheckClustering PUBLIC ${CPPGSL_INCLUDE_DIR})
set_property(TARGET CheckClustering PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)
