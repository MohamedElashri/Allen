include_directories(include)
include_directories(main/include)

file(GLOB backend_sources "src/*cpp")

allen_add_device_library(Backend STATIC ${backend_sources})
