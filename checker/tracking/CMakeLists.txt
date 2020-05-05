include_directories(include)
include_directories(${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/PrVeloUT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/UT/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/event_model/SciFi/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/kalman/ParKalman/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/PV/beamlinePV/include)

file(GLOB tracking_checker_sources "src/*cpp")

add_library(TrackChecking STATIC
  ${tracking_checker_sources}
)
target_include_directories(TrackChecking PUBLIC ${CPPGSL_INCLUDE_DIR})

if(APPLE OR (CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.0))
  find_package(Boost COMPONENTS filesystem)
  target_compile_definitions(TrackChecking PRIVATE USE_BOOST_FILESYSTEM)
  target_link_libraries(TrackChecking PRIVATE Boost::filesystem)
else()
  find_package(Filesystem)
  target_link_libraries(TrackChecking PRIVATE std::filesystem)
endif()

if(ROOT_FOUND)
  target_compile_definitions(TrackChecking PRIVATE ${ALLEN_ROOT_DEFINITIONS})
  target_include_directories(TrackChecking SYSTEM BEFORE PRIVATE
    ${ROOT_INCLUDE_DIRS}
  )
endif()

if(USE_KALMAN_SINGLE_PRECISION)
  target_compile_definitions(TrackChecking PRIVATE KALMAN_SINGLE_PRECISION)
endif()
