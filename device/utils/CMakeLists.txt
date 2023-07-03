###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB prefix_sum "prefix_sum/src/*cu")
file(GLOB get_type_id "get_type_id/src/*cu")

add_library(UtilsHeaders INTERFACE)

target_link_libraries(UtilsHeaders
  INTERFACE
    Backend
    EventModel
    HostEventModel)

target_include_directories(UtilsHeaders INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/binary_search/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sorting/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/float_operations/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/memory/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/scaler/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tuple_operations/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/warp/include>)

allen_add_device_library(Utils STATIC
  ${prefix_sum}
  ${get_type_id}
)

target_link_libraries(Utils
  PUBLIC
    UtilsHeaders
    PRIVATE
      Backend
      EventModel
      HostEventModel)

target_include_directories(Utils PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/prefix_sum/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/get_type_id/include>)
