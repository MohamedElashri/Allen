file(GLOB global_event_cut "src/*cu")

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${global_event_cut} PROPERTIES LANGUAGE CXX)
endif()

allen_add_library(GlobalEventCut STATIC
  ${global_event_cut}
)
