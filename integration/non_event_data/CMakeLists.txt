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
file(GLOB SOURCES "src/*.cpp")

allen_add_host_library(NonEventData STATIC ${SOURCES})
add_library(NonEventDataHeaders INTERFACE)
target_include_directories(NonEventDataHeaders INTERFACE
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/Dumpers/BinaryDumpers/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
install(TARGETS NonEventDataHeaders EXPORT Allen)

target_link_libraries(NonEventData
  PRIVATE
    AllenRuntime
    AllenCommon
    HostCommon
    EventModel
    Gear
    MuonCommon
    UTCommon
    nlohmann_json::nlohmann_json
  PUBLIC
    NonEventDataHeaders
  )
