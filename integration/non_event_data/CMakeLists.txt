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
  ${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include
  ${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include
  ${CMAKE_SOURCE_DIR}/cuda/event_model/muon/include
  ${CMAKE_SOURCE_DIR}/cuda/event_model/common/include
  ${CMAKE_SOURCE_DIR}/cuda/velo/common/include
  ${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include
  ${CMAKE_SOURCE_DIR}/cuda/PV/common/include
  ${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include
  ${CMAKE_SOURCE_DIR}/cuda/muon/common/include
  ${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include
  ${CMAKE_SOURCE_DIR}/cuda/SciFi/classifiers/include
  ${CMAKE_SOURCE_DIR}/cuda/UT/common/include
  ${CMAKE_SOURCE_DIR}/stream/sequence/include
  ${CMAKE_SOURCE_DIR}/checker/tracking/include
  ${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include
  ${CMAKE_SOURCE_DIR}/x86/velo/clustering/include
  ${CMAKE_SOURCE_DIR}/x86/SciFi/MomentumForward/include
  ${CMAKE_SOURCE_DIR}/cuda/SciFi/looking_forward/common/include/
  ${CMAKE_SOURCE_DIR}/main/include)
