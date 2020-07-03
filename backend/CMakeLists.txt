include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)

file(GLOB backend_sources "src/*cu")
file(GLOB backend_sources "src/*cpp")

allen_add_device_library(Backend STATIC ${backend_sources})
