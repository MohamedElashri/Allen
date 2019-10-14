file(GLOB cpu_gec "src/*cu")

include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/setup/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/SciFi/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/UT/common/include)
include_directories(${CMAKE_SOURCE_DIR}/cuda/global_event_cut/include)

if(TARGET_DEVICE STREQUAL "CPU")
  set_source_files_properties(${cpu_gec} PROPERTIES LANGUAGE CXX)
endif()

allen_add_library(CpuGEC STATIC
  ${cpu_gec}
)

add_executable(mep_gec test/mep_gec.cpp)

target_include_directories(mep_gec PUBLIC
  ${CMAKE_SOURCE_DIR}/mdf/include
  ${CMAKE_SOURCE_DIR}/stream/gear/include
  ${CMAKE_SOURCE_DIR}/x86/global_event_cut/include
  ${CMAKE_SOURCE_DIR}/main/include)

target_link_libraries(mep_gec PRIVATE Common mdf CpuGEC
  ${MPI_CXX_LIBRARIES})
target_compile_definitions(mep_gec PUBLIC NO_CUDA)

install(TARGETS mep_gec RUNTIME DESTINATION bin OPTIONAL)
