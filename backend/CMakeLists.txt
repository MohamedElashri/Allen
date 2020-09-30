include_directories(include)
include_directories(main/include)

file(GLOB backend_sources "src/*cpp")

allen_add_device_library(Backend STATIC ${backend_sources})

if (ROOT_FOUND)
  target_compile_definitions(Stream PUBLIC ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Stream SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
