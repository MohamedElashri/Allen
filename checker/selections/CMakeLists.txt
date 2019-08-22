include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)
include_directories(${CMAKE_SOURCE_DIR}/checker/tracking/include)

file(GLOB selection_checker_sources "src/*cpp")

add_library(SelChecking STATIC
  ${selection_checker_sources}
)
set_target_properties(SelChecking PROPERTIES POSITION_INDEPENDENT_CODE ON)
