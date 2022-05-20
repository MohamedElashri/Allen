###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB SOURCES "src/*.cpp")

allen_add_host_library(NonEventData STATIC ${SOURCES})

target_link_libraries(NonEventData PRIVATE
  HostClustering
  Backend
  AllenCommon
  EventModel
  Gear
  Backend
  MuonCommon
  TrackChecking
  UT
  nlohmann_json::nlohmann_json)

target_include_directories(NonEventData PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
if (STANDALONE)
target_include_directories(NonEventData PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/Dumpers/BinaryDumpers/include>)
else()
  target_link_libraries(NonEventData PUBLIC BinaryDumpers)
endif()
