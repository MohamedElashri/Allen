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
add_library(WrapperInterface INTERFACE)

add_subdirectory(utils)
add_subdirectory(velo)
add_subdirectory(PV/beamlinePV)
add_subdirectory(associate)
add_subdirectory(UT)
add_subdirectory(SciFi)
add_subdirectory(track_matching)
add_subdirectory(calo)
add_subdirectory(muon)
add_subdirectory(kalman)
add_subdirectory(vertex_fit)
add_subdirectory(example)
add_subdirectory(selections)
add_subdirectory(event_model)
add_subdirectory(validators)
add_subdirectory(lumi)
add_subdirectory(combiners)
add_subdirectory(plume)
add_subdirectory(downstream)
add_subdirectory(rich)
