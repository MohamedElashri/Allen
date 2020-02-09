include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/vertex_fit/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/raw_banks/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/selections/Hlt1/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)

file(GLOB selection_checker_sources "src/*.cpp")

add_library(SelChecking STATIC
  ${selection_checker_sources}
)
set_target_properties(SelChecking PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(SelChecking PUBLIC ${CPPGSL_INCLUDE_DIRS})

if(USE_ROOT AND ROOT_FOUND)
  target_compile_definitions(SelChecking PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(SelChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()
