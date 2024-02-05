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
file(GLOB monitoring_sources_cpp "src/*cpp")

allen_add_host_library(Monitoring STATIC
  ${monitoring_sources_cpp}
)

target_link_libraries(Monitoring PRIVATE AllenZMQ Gear Backend VertexFitter EventModel
  Selections)

target_include_directories(Monitoring PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if (NOT STANDALONE)
  target_compile_definitions(Monitoring PUBLIC GAUDI_BUILD)
  target_link_libraries(Monitoring PRIVATE Gaudi::GaudiUtilsLib)
endif()
