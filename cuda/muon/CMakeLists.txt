file(GLOB muon_features_extraction "preprocessing/src/*cu")
file(GLOB muon_classification "classification/src/*cu")
file(GLOB muon_filtering "is_muon/src/*cu")
file(GLOB muon_decoding "decoding/src/*cu")
file(GLOB muon_decoding_steps "decoding_steps/src/*cu")

include_directories(preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(common/include)
include_directories(is_muon/include)
include_directories(classification/include)
include_directories(decoding/include)
include_directories(decoding_steps/include)

if(TARGET_DEVICE STREQUAL "CPU")
  foreach(source_file ${muon_filtering} ${muon_features_extraction}
    ${muon_classification} ${muon_decoding} ${muon_decoding_steps})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_library(Muon STATIC
  ${muon_filtering}
  ${muon_features_extraction}
  ${muon_classification}
  ${muon_decoding}
  ${muon_decoding_steps}
)

target_link_libraries(Muon Utils)
