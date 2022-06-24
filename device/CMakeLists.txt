###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
add_library(WrapperInterface INTERFACE)

add_subdirectory(utils)
add_subdirectory(velo)
add_subdirectory(PV/beamlinePV)
add_subdirectory(associate)
add_subdirectory(UT)
add_subdirectory(SciFi)
add_subdirectory(calo)
add_subdirectory(muon)
add_subdirectory(kalman)
add_subdirectory(vertex_fit)
add_subdirectory(example)
add_subdirectory(selections)
add_subdirectory(event_model)
add_subdirectory(validators)
add_subdirectory(lumi)
