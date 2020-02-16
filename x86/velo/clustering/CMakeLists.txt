include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)

file(GLOB host_clustering "src/*cpp")

# to do: why do I need nvcc to compile the x86 code?
# it depends on clustering functions in cuda/velo/mask_clustering,
# we should make them __host__ and __device__ functions
allen_add_host_library(HostClustering STATIC ${host_clustering})

target_include_directories(HostClustering PRIVATE ${CPPGSL_INCLUDE_DIR})
