include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${ROOT_INCLUDE_DIRS})

file(GLOB selection_checker_sources "src/*cpp")

add_library(SelChecking SHARED
  ${selection_checker_sources}
)
set_target_properties(SelChecking PROPERTIES POSITION_INDEPENDENT_CODE ON)
