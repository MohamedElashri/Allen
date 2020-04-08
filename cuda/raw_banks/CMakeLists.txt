include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CPPGSL_INCLUDE_DIR})

file(GLOB raw_banks_src "src/*cu")

allen_add_device_library(RawBanks STATIC
  ${raw_banks_src}
)

set_property(TARGET RawBanks PROPERTY CUDA_SEPARABLE_COMPILATION ON)
