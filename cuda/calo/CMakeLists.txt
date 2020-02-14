file(GLOB calo_decoding "decoding/src/*cu")

include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(../event_model/common/include)
include_directories(../utils/sorting/include)
include_directories(../utils/binary_search/include)
include_directories(../utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)

if(TARGET_DEVICE STREQUAL "CPU")
  foreach(source_file ${calo_decoding})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_library(CaloDecoding STATIC
  ${calo_decoding}
)

allen_add_library(Calo STATIC
  ${calo_decoding}
)
