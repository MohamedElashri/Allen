###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB associate_srcs "src/*.cu")

allen_add_device_library(Associate STATIC
  ${associate_srcs}
)

target_link_libraries(Associate PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Associate PUBLIC include)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
