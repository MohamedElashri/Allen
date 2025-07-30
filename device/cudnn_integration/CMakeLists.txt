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

file(GLOB cudnn_integration_sources "src/*cu")

# Create the library
allen_add_device_library(CuDNNIntegration STATIC
  ${cudnn_integration_sources}
)

target_link_libraries(CuDNNIntegration PRIVATE Backend HostEventModel EventModel Utils)
target_include_directories(CuDNNIntegration PUBLIC 
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

# Link CuDNN if available (only for CUDA builds)
if(TARGET_DEVICE STREQUAL "CUDA" AND CUDNN_FOUND)
  target_link_libraries(CuDNNIntegration PRIVATE CuDNN::CuDNN)
  target_compile_definitions(CuDNNIntegration PRIVATE CUDNN_AVAILABLE)
  message(STATUS "CuDNN integration enabled for CuDNNIntegration library")
else()
  if(TARGET_DEVICE STREQUAL "CUDA")
    message(WARNING "CuDNN not found. CuDNN functionality will be disabled in CuDNNIntegration library.")
  endif()
endif()
