include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/classifiers/include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})

file(GLOB x86MomentumForward "src/*cpp" )

add_library(x86MomentumForward STATIC
  ${x86MomentumForward}
)

set_property(TARGET x86MomentumForward PROPERTY
             CUDA_RESOLVE_DEVICE_SYMBOLS ON)

if (USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(x86MomentumForward PUBLIC WITH_ROOT)
  target_include_directories(x86MomentumForward SYSTEM BEFORE PRIVATE ${ROOT_INCLUDE_DIRS})
endif()
