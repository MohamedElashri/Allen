file(GLOB blPV "src/*.cu")

include_directories(include)
include_directories(../common/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/veloUT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/x86/PV/beamlinePV/include)
include_directories(${CPPGSL_INCLUDE_DIR})

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  set_source_files_properties(${blPV} PROPERTIES LANGUAGE CXX)
endif()

allen_add_device_library(PV_beamline STATIC
  ${blPV})

if(USE_ROOT AND ROOT_FOUND)
  add_library(PV_monitoring STATIC src/pv_beamline_monitoring.cpp)
  target_compile_definitions(PV_monitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(PV_monitoring SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS})
  target_link_libraries(PV_beamline PRIVATE PV_monitoring)
endif()
