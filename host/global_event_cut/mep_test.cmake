###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
add_executable(mep_gec test/mep_gec.cpp ${PROJECT_SOURCE_DIR}/backend/src/CPUBackend.cpp
  ${PROJECT_SOURCE_DIR}/host/global_event_cut/src/HostGlobalEventCut.cpp)

target_include_directories(mep_gec PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

target_link_libraries(mep_gec PRIVATE
  HostGEC
  HostEventModel
  EventModel
  Gear
  AllenCommon
  Backend
  HostCommon
  LHCbEvent
  struct_to_tuple
  ${MPI_CXX_LIBRARIES})

if (NOT STANDALONE)
  find_package(fmt REQUIRED)
  target_link_libraries(mep_gec PRIVATE fmt::fmt)
endif()

target_compile_definitions(mep_gec PUBLIC TARGET_DEVICE_CPU)
add_dependencies(mep_gec struct_to_tuple)

install(TARGETS mep_gec RUNTIME DESTINATION bin OPTIONAL)
