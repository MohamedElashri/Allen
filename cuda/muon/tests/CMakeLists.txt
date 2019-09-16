include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/IsMuon/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(include)

set(UNIT_TEST_LIST
  MuonFeaturesExtraction MuonRawToHits)

foreach(NAME IN LISTS UNIT_TEST_LIST)

  add_compile_definitions(SOURCE_DIR="${CMAKE_SOURCE_DIR}")
  set(TARGET_NAME ${NAME}.test)
  add_executable(${TARGET_NAME}
    "src/main.cu"
    "src/${NAME}.test.cu")

  target_link_libraries(${TARGET_NAME}
    PUBLIC Muon x86MuonDecoding Common Velo)

  set_property(TARGET ${TARGET_NAME} PROPERTY CUDA_SEPARABLE_COMPILATION ON)

  add_test(
    NAME ${TARGET_NAME}
    COMMAND ${TARGET_NAME})
endforeach()
