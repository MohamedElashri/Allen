###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB muon_features_extraction "preprocessing/src/*cu")
file(GLOB muon_classification "classification/src/*cu")
file(GLOB muon_filtering "is_muon/src/*cu")
file(GLOB muon_decoding "decoding/src/*cu")
file(GLOB muon_upstream_filtering "match_upstream_muon/src/*cu")
file(GLOB muon_velo_filtering "match_velo_muon/src/*cu")
file(GLOB muon_filter "muon_filter/src/*cu")
file(GLOB consolidate_muon "consolidate_muon/src/*cu")



allen_add_device_library(Muon STATIC
  ${muon_filtering}
  ${muon_features_extraction}
  ${muon_classification}
  ${muon_decoding}
  ${muon_upstream_filtering}
  ${muon_velo_filtering}
  ${muon_filter}
  ${consolidate_muon}
)

add_library(MuonCommon INTERFACE)
target_include_directories(MuonCommon INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common/include>
)
install(TARGETS MuonCommon EXPORT Allen)

target_link_libraries(Muon PRIVATE AllenCommon Backend HostEventModel EventModel Utils)
target_link_libraries(Muon PUBLIC MuonCommon)

target_include_directories(Muon PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/preprocessing/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/is_muon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/match_upstream_muon/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/muon_filter/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/classification/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/decoding/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/match_velo_muon/include>
  )
