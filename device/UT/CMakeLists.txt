###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB UT_decoding "UTDecoding/src/*cu")
file(GLOB UT_consolidate "consolidate/src/*cu")
file(GLOB CompassUT_tracking "compassUT/src/*cu")

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/binary_search/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})
include_directories(common/include)
include_directories(UTDecoding/include)
include_directories(consolidate/include)
include_directories(compassUT/include)

allen_add_device_library(UT STATIC
  ${UT_decoding}
  ${UT_consolidate}
  ${CompassUT_tracking}
)
