###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
file(GLOB muon_features_extraction "preprocessing/src/*cu")
file(GLOB muon_classification "classification/src/*cu")
file(GLOB muon_filtering "is_muon/src/*cu")
file(GLOB muon_decoding "decoding/src/*cu")
file(GLOB muon_upstream_filtering "match_upstream_muon/src/*cu")
file(GLOB muon_velo_filtering "match_velo_muon/src/*cu")
file(GLOB muon_filter "muon_filter/src/*cu")
file(GLOB consolidate_muon "consolidate_muon/src/*cu")
file(GLOB chi2corr "chi2corr/src/*cu")
file(GLOB muonid_nn "muonid_nn/src/*cu")
file(GLOB consolidate_muon "consolidate_tracks/src/*cu")



allen_add_device_library(Muon STATIC
  ${muon_filtering}
  ${muon_features_extraction}
  ${muon_classification}
  ${muon_decoding}
  ${muon_upstream_filtering}
  ${muon_velo_filtering}
  ${muon_filter}
  ${consolidate_muon}
  ${chi2corr}
  ${muonid_nn}
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
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/consolidate_tracks/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/chi2corr/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/muonid_nn/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/utils/nn_propagation/include>
  )
