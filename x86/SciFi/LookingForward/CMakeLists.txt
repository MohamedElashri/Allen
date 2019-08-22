include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/SciFi/MomentumForward/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
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
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/utils/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)

file(GLOB x86LookingForward "src/*cpp" )

add_library(x86LookingForward STATIC
	${x86LookingForward}
)

set_property(TARGET x86LookingForward PROPERTY
             CUDA_SEPARABLE_COMPILATION ON)
set_property(TARGET x86LookingForward PROPERTY
             CUDA_RESOLVE_DEVICE_SYMBOLS ON)

if ( ROOT_FOUND )
  target_compile_definitions(x86LookingForward PUBLIC WITH_ROOT)
  target_include_directories(x86LookingForward BEFORE PRIVATE ${ROOT_INCLUDE_DIRS})
endif()
