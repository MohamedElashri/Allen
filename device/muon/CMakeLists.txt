file(GLOB muon_features_extraction "preprocessing/src/*cu")
file(GLOB muon_classification "classification/src/*cu")
file(GLOB muon_filtering "is_muon/src/*cu")
file(GLOB muon_decoding "decoding/src/*cu")
file(GLOB muon_upstream_filtering "match_upstream_muon/src/*cu")
file(GLOB muon_filter "muon_filter/src/*cu")

include_directories(preprocessing/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/consolidate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/muon/include)
include_directories(common/include)
include_directories(is_muon/include)
include_directories(match_upstream_muon/include)
include_directories(muon_filter/include)
include_directories(classification/include)
include_directories(decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/associate/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/UTDecoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include/)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIR})

allen_add_device_library(Muon STATIC
  ${muon_filtering}
  ${muon_features_extraction}
  ${muon_classification}
  ${muon_decoding}
  ${muon_upstream_filtering}
  ${muon_filter}
)

target_link_libraries(Muon Utils)

