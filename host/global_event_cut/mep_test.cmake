###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
add_executable(mep_gec test/mep_gec.cpp ${CMAKE_SOURCE_DIR}/backend/src/CPUBackend.cpp
  ${CMAKE_SOURCE_DIR}/host/global_event_cut/src/HostGlobalEventCut.cpp)

target_include_directories(mep_gec PUBLIC include)

target_link_libraries(mep_gec PRIVATE
  HostGEC
  HostEventModel
  EventModel
  Gear
  AllenCommon
  Backend
  HostCommon
  LHCbEvent
  ${MPI_CXX_LIBRARIES})

if (NOT STANDALONE)
  find_package(fmt REQUIRED)
  target_link_libraries(mep_gec PRIVATE fmt::fmt)
endif()

target_compile_definitions(mep_gec PUBLIC TARGET_DEVICE_CPU)

install(TARGETS mep_gec RUNTIME DESTINATION bin OPTIONAL)
