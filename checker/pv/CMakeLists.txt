###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/device/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)
include_directories(${CMAKE_SOURCE_DIR}/backend/include)
include_directories(${ROOT_INCLUDE_DIRS})
include_directories(${CPPGSL_INCLUDE_DIR})

file(GLOB pv_checker_sources "src/*cpp")

allen_add_host_library(PVChecking STATIC
  ${pv_checker_sources}
)
target_include_directories(PVChecking PUBLIC ${CPPGSL_INCLUDE_DIR})

if(USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(PVChecking PRIVATE WITH_ROOT)
  target_include_directories(PVChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS} ${CPPGSL_INCLUDE_DIR}
  )
  # Locally suppress float->double promotion warnings caused by (marvellous) ROOT TH interfaces
  string(APPEND CMAKE_CXX_FLAGS " -Wno-double-promotion ")
endif()
