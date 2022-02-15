###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
include_directories(filters/include)
include_directories(lines/calibration/include)
include_directories(lines/charm/include)
include_directories(lines/inclusive_hadron/include)
include_directories(lines/muon/include)
include_directories(lines/electron/include)
include_directories(lines/photon/include)
include_directories(lines/monitoring/include)
include_directories(lines/SMOG2/include)
include_directories(line_types/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/calo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/selections/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/device/utils/tuple_operations/include)
include_directories(${CMAKE_SOURCE_DIR}/device/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/external)
include_directories(${CMAKE_SOURCE_DIR}/mdf/lhcb)
include_directories(${CMAKE_SOURCE_DIR}/host/prefix_sum/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${PROJECT_BINARY_DIR}/code_generation/configuration/sequences)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CPPGSL_INCLUDE_DIR})
include_directories(${Boost_INCLUDE_DIRS})

if (NOT GaudiProject_FOUND)
  # add local copy of headers for standalone build (downloaded in subdir mdf)
  include_directories(${PROJECT_BINARY_DIR}/imported_include)
else()
  # Get Event/ODIN.h from LHCb if not STANDALONE
  include_directories(${LHCB_PREFIX_DIR}/include)
endif()

add_compile_definitions(ODIN_WITHOUT_GAUDI)

file(GLOB selections_src "Hlt1/src/*cu")
file(GLOB filters_src "filters/src/*cu")
file(GLOB lines_src "lines/calibration/src/*cu" "lines/charm/src/*cu" "lines/inclusive_hadron/src/*cu" "lines/inclusive_hadron/src/*cpp" "lines/muon/src/*cu" "lines/photon/src/*cu" "lines/electron/src/*cu" "lines/monitoring/src/*cu" "lines/SMOG2/src/*cu")

if(SEPARABLE_COMPILATION)
  allen_add_device_library(Selections STATIC
    ${lines_src}
    ${selections_src}
    ${filters_src}
  )
else()
  allen_add_device_library_unified(Selections STATIC
    ${lines_src}
    ${selections_src}
    ${filters_src}
  )
endif()

target_link_libraries(Selections PRIVATE
  AllenCommon
  Backend
  HostEventModel
  EventModel
  Utils
  LHCbEvent
  Kalman
  VertexFitter
  extern_lines)

if(USE_ROOT)
  # Locally suppress float->double promotion warnings caused by ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()

target_include_directories(Selections PUBLIC
  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/configuration/sequences>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Hlt1/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/calibration/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/monitoring/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/charm/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/inclusive_hadron/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/muon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/electron/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lines/photon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/line_types/include>)
