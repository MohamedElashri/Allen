include_directories(ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CPPGSL_INCLUDE_DIR})

file(GLOB kalman_ParKalman "ParKalman/src/*cu")

allen_add_device_library(Kalman STATIC
  ${kalman_ParKalman}
)

target_link_libraries(Kalman SciFi Associate)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
