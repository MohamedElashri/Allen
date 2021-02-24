###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB selections_src "Hlt1/src/*cu")
file(GLOB lines_src "lines/calibration/src/*cu" "lines/charm/src/*cu" "lines/inclusive_hadron/src/*cu" "lines/inclusive_hadron/src/*cpp" "lines/muon/src/*cu" "lines/photon/src/*cu" "lines/electron/src/*cu" "lines/monitoring/src/*cu")
allen_add_device_library(Selections STATIC
  ${selections_src}
  ${lines_src}
)

target_link_libraries(Selections PRIVATE Backend HostEventModel EventModel Utils LHCbEvent
  Configuration Kalman VertexFitter)

add_dependencies(Selections configured_sequence)

target_include_directories(Selections PUBLIC
  Hlt1/include
  lines/calibration/include
  lines/monitoring/include
  lines/charm/include
  lines/inclusive_hadron/include
  lines/muon/include
  line_types/include)
