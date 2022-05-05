###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB svs_pair_candidate_src "src/*cu")

allen_add_device_library(Svs_pair_cand STATIC
  ${svs_pair_candidate_src}
)

target_link_libraries(Svs_pair_cand PUBLIC Kalman PRIVATE Backend HostEventModel EventModel Utils)

target_include_directories(VertexFitter PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)


if (USE_KALMAN_DOUBLE_PRECISION)
  add_compile_definitions(KALMAN_DOUBLE_PRECISION)
endif()











#file(GLOB svs_pair_candidates_sources "src/*cu")

#include_directories(include)
#include_directories(${PROJECT_SOURCE_DIR}/device/velo/common/include)
#include_directories(${PROJECT_SOURCE_DIR}/device/event_model/common/include)
#include_directories(${PROJECT_SOURCE_DIR}/device/event_model/velo/include)
#include_directories(${PROJECT_SOURCE_DIR}/main/include)
#include_directories(${PROJECT_SOURCE_DIR}/stream/gear/include)
#include_directories(${PROJECT_SOURCE_DIR}/stream/sequence/include)

#allen_add_device_library(Svs_pair_cand STATIC
#  ${svs_pair_candidates_sources}
#)
