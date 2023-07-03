###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
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
    HostClustering
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
