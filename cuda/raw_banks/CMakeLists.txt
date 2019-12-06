include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)

file(GLOB raw_banks_src "src/*cu")

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${raw_banks_src} PROPERTIES LANGUAGE CXX)
endif()

add_library(RawBanks STATIC
  ${raw_banks_src}
  )

set_property(TARGET RawBanks PROPERTY CUDA_SEPARABLE_COMPILATION ON)

