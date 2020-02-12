file(GLOB prefix_sum "prefix_sum/src/*cu")

include_directories(prefix_sum/include/)
include_directories(binary_search/include/)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${prefix_sum} PROPERTIES LANGUAGE CXX)
endif()

allen_add_library(Utils STATIC
  ${prefix_sum}
)
