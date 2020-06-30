###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/zmq/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${ROOT_INCLUDE_DIRS})
include_directories(${CPPGSL_INCLUDE_DIR})

file(GLOB monitoring_sources_cpp "src/*cpp")

allen_add_host_library(AllenMonitoring STATIC
  ${monitoring_sources_cpp}
)
target_link_libraries(AllenMonitoring PRIVATE AllenZMQ)

if (GaudiProject_FOUND)
  target_compile_definitions(AllenMonitoring PUBLIC GAUDI_BUILD)
  gaudi_resolve_link_libraries(GAUDI_UTILS_LIB GaudiUtilsLib)
  target_link_libraries(AllenMonitoring PRIVATE ${GAUDI_UTILS_LIB})
endif()

if(ROOT_FOUND)
  target_compile_definitions(AllenMonitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(AllenMonitoring SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()
