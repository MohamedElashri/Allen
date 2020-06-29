include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)

file(GLOB backend_sources "src/*cpp")

allen_add_device_library(Backend STATIC ${backend_sources})
