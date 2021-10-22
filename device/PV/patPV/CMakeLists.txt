###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB pat_pv "src/*cu")

allen_add_device_library(AllenPatPV STATIC
  ${pat_pv}
)

target_link_libraries(AllenPatPV PRIVATE AllenCommon Backend HostEventModel EventModel Utils)

target_include_directories(AllenPatPV PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../beamlinePV/include>)
