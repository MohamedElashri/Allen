###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
file(GLOB muon_features_extraction "preprocessing/src/*cu")
file(GLOB muon_classification "classification/src/*cu")
file(GLOB muon_filtering "is_muon/src/*cu")
file(GLOB muon_decoding "decoding/src/*cu")
file(GLOB muon_upstream_filtering "match_upstream_muon/src/*cu")
file(GLOB muon_filter "muon_filter/src/*cu")

allen_add_device_library(Muon STATIC
  ${muon_filtering}
  ${muon_features_extraction}
  ${muon_classification}
  ${muon_decoding}
  ${muon_upstream_filtering}
  ${muon_filter}
)

target_link_libraries(Muon PRIVATE Common Backend EventModel Utils)

target_include_directories(Muon PUBLIC
  preprocessing/include
  common/include
  is_muon/include
  match_upstream_muon/include
  muon_filter/include
  classification/include
  decoding/include)
