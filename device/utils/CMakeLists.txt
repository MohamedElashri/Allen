###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB prefix_sum "prefix_sum/src/*cu")

include_directories(prefix_sum/include/)
include_directories(binary_search/include/)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/looking_forward/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/muon/decoding/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CPPGSL_INCLUDE_DIR})

allen_add_device_library(Utils STATIC
  ${prefix_sum}
)
