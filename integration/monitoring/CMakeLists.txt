###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB monitoring_sources_cpp "src/*cpp")

allen_add_host_library(AllenMonitoring STATIC
  ${monitoring_sources_cpp}
)

target_link_libraries(AllenMonitoring PRIVATE AllenZMQ Gear Backend VertexFitter EventModel
  Selections)

target_include_directories(AllenMonitoring PUBLIC include)

if (GaudiProject_FOUND)
  target_compile_definitions(AllenMonitoring PUBLIC GAUDI_BUILD)
  gaudi_resolve_link_libraries(GAUDI_UTILS_LIB GaudiUtilsLib)
  target_link_libraries(AllenMonitoring PRIVATE ${GAUDI_UTILS_LIB})
endif()

if(ROOT_FOUND)
  target_compile_definitions(AllenMonitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(AllenMonitoring PUBLIC include SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()
