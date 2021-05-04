###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB kalman_ParKalman "ParKalman/src/*cu")

allen_add_device_library(Kalman STATIC
  ${kalman_ParKalman}
)

target_link_libraries(Kalman PUBLIC SciFi Associate
  PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(Kalman PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ParKalman/include>)

if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()
