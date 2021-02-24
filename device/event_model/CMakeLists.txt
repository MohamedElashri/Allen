###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
add_library(EventModel INTERFACE)

target_include_directories(EventModel INTERFACE
  associate/include
  common/include
  calo/include
  muon/include
  SciFi/include
  selections/include
  UT/include
  velo/include
  kalman/include
  PV/include)
