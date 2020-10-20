###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
include_directories(ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

file(GLOB kalman_ParKalman "ParKalman/src/*cu")

allen_add_device_library(Kalman STATIC
  ${kalman_ParKalman}
)

target_link_libraries(Kalman SciFi Associate)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
