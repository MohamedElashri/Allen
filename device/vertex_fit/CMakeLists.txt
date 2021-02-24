###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB vertex_fitter_src "vertex_fitter/src/*cu")
file(GLOB two_track_catboost_src "two_track_catboost/src/*cu")
file(GLOB two_track_mva_src "two_track_mva/src/*cu")

allen_add_device_library(VertexFitter STATIC
  ${vertex_fitter_src}
  ${two_track_catboost_src}
  ${two_track_mva_src}
)

target_link_libraries(VertexFitter PUBLIC Kalman PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(VertexFitter PUBLIC
  common/include
  two_track_catboost/include
  vertex_fitter/include)


if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
