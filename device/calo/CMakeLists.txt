file(GLOB calo_decoding "decoding/src/*cu")
file(GLOB calo_clustering "clustering/src/*cu")

include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(decoding/include)
include_directories(event_model/include)
include_directories(clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${Boost_INCLUDE_DIRS})

allen_add_device_library(Calo STATIC
  ${calo_decoding}
  ${calo_clustering}
)
