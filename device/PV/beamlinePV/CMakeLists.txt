file(GLOB blPV "src/*.cu")

include_directories(include)
include_directories(../common/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/veloUT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/sorting/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/float_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/host/PV/beamlinePV/include)
include_directories(${CPPGSL_INCLUDE_DIR})

allen_add_device_library(PV_beamline STATIC
  ${blPV})

if(USE_ROOT AND ROOT_FOUND)
  add_library(PV_monitoring STATIC src/pv_beamline_monitoring.cpp)
  target_compile_definitions(PV_monitoring PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(PV_monitoring SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS})
  target_link_libraries(PV_beamline PRIVATE PV_monitoring)
endif()
