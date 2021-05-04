###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB validators "src/*cpp")

allen_add_host_library(Validators STATIC
  ${validators}
)

target_link_libraries(Validators PRIVATE
  TrackChecking
  SelChecking
  PVChecking
  HostEventModel
  EventModel
  Gear
  Common
  Backend)

target_include_directories(Validators PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

if(ROOT_FOUND)
  target_compile_definitions(Validators PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(Validators SYSTEM BEFORE PRIVATE ${ROOT_INCLUDE_DIRS}
    )
  # Suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  set_target_properties(Validators PROPERTIES COMPILE_FLAGS " -Wno-double-promotion ")
endif()
