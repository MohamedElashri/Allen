###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB pvinference_sources "src/*.cu")

include_directories(include)
include_directories(${PROJECT_SOURCE_DIR}/device/velo/common/include)
include_directories(${PROJECT_SOURCE_DIR}/device/event_model/common/include)
include_directories(${PROJECT_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${PROJECT_SOURCE_DIR}/device/event_model/kalman/include)
include_directories(${PROJECT_SOURCE_DIR}/main/include)
include_directories(${PROJECT_SOURCE_DIR}/stream/gear/include)
include_directories(${PROJECT_SOURCE_DIR}/stream/sequence/include)

allen_add_device_library(PVinference STATIC
  ${pvinference_sources}
)

target_link_libraries(PVinference PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(PVinference PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

# Define compile-time path to weights file
target_compile_definitions(PVinference PRIVATE 
  PVINFERENCE_WEIGHTS_PATH="${CMAKE_CURRENT_SOURCE_DIR}/include/weights/pvfinder_weights.bin"
)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
