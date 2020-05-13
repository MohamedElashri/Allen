file(GLOB saxpy_sources "src/*cu")

include_directories(include)
include_directories(../velo/common/include)
include_directories(../event_model/common/include)
include_directories(../event_model/velo/include)

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CPPGSL_INCLUDE_DIR})

allen_add_device_library(Saxpy STATIC
  ${saxpy_sources}
)
