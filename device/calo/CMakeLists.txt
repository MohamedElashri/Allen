file(GLOB calo_event "event_model/src/*cu")
file(GLOB calo_decoding "decoding/src/*cu")
file(GLOB calo_clustering "clustering/src/*cu")

include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(decoding/include)
include_directories(event_model/include)
include_directories(clustering/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)

if(TARGET_DEVICE STREQUAL "CPU")
  foreach(source_file ${calo_event} ${calo_decoding} ${calo_clustering})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_device_library(Calo STATIC
  ${calo_event}
  ${calo_decoding}
  ${calo_clustering}
)
