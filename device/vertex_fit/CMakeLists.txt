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
file(GLOB vertex_fitter_src "vertex_fitter/src/*cu")
file(GLOB two_track_mva_src "two_track_mva/src/*cu")
file(GLOB prompt_vertex_src "prompt_vertex/src/*cu")

allen_add_device_library(VertexFitter STATIC
  ${vertex_fitter_src}
  ${two_track_catboost_src}
  ${two_track_mva_src}
  ${prompt_vertex_src}
)

target_link_libraries(VertexFitter PUBLIC Kalman PRIVATE Backend HostEventModel EventModel Utils)


target_include_directories(VertexFitter PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/utils/nn_propagation/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/two_track_mva/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/vertex_fitter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/prompt_vertex/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/utils/nn_propagation/include>)


if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
