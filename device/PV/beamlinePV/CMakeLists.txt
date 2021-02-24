###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB blPV "src/*.cu")

allen_add_device_library(PV_beamline STATIC
  ${blPV})

target_link_libraries(PV_beamline PRIVATE Common Backend HostEventModel EventModel Utils)

target_include_directories(PV_beamline PUBLIC include)

if(USE_ROOT AND ROOT_FOUND)
  add_library(PV_monitoring STATIC src/pv_beamline_monitoring.cpp)
  target_compile_definitions(PV_monitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})

  target_include_directories(PV_monitoring PUBLIC include)
  target_include_directories(PV_monitoring SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS})

  target_link_libraries(PV_monitoring PRIVATE Common)

  target_link_libraries(PV_beamline PRIVATE PV_monitoring)
endif()
