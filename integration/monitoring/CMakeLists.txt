include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/zmq/include)
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
endif()
