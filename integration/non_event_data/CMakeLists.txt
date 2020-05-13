file(GLOB SOURCES "src/*.cpp")

allen_add_host_library(NonEventData ${SOURCES})

include_directories(${CPPGSL_INCLUDE_DIR})

target_link_libraries(NonEventData
  HostClustering
  CudaCommon
  Common)

target_include_directories(NonEventData PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

target_include_directories(NonEventData PUBLIC
  ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
  ${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include
  ${CMAKE_SOURCE_DIR}/device/event_model/velo/include
  ${CMAKE_SOURCE_DIR}/device/event_model/muon/include
  ${CMAKE_SOURCE_DIR}/device/event_model/common/include
  ${CMAKE_SOURCE_DIR}/device/velo/common/include
  ${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include
  ${CMAKE_SOURCE_DIR}/device/PV/common/include
  ${CMAKE_SOURCE_DIR}/device/SciFi/common/include
  ${CMAKE_SOURCE_DIR}/device/muon/common/include
  ${CMAKE_SOURCE_DIR}/device/muon/decoding/include
  ${CMAKE_SOURCE_DIR}/device/SciFi/classifiers/include
  ${CMAKE_SOURCE_DIR}/device/UT/common/include
  ${CMAKE_SOURCE_DIR}/stream/sequence/include
  ${CMAKE_SOURCE_DIR}/checker/tracking/include
  ${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include
  ${CMAKE_SOURCE_DIR}/host/velo/clustering/include
  ${CMAKE_SOURCE_DIR}/host/SciFi/MomentumForward/include
  ${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/common/include/
  ${CMAKE_SOURCE_DIR}/main/include)
