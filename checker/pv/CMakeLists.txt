###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB pv_checker_sources "src/*cpp")

allen_add_host_library(PVChecking STATIC
  ${pv_checker_sources}
)
target_include_directories(PVChecking PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries(PVChecking PRIVATE HostEventModel EventModel Gear Backend Common TrackChecking)

if(USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(PVChecking PRIVATE WITH_ROOT)
  target_include_directories(PVChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS} ${CPPGSL_INCLUDE_DIR}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()
