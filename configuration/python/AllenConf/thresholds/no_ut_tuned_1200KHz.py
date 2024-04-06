###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.thresholds.thresholds import Thresholds

threshold_settings = Thresholds(
    TrackMuonMVA_maxCorrChi2=1.8,
    DiMuonDisplaced_maxCorrChi2=1.8,
    D2HH_ctIPScale=1.,
    TrackMVA_alpha=500,
    TrackElectronMVA_alpha=2000,
    TrackMuonMVA_alpha=-700,
    D2HH_track_ip=0.07,
    D2HH_track_pt=700,
    SingleHighPtLepton_pt=4900,
    SingleHighPtLepton_pt_noMuonID=4900,
    TwoTrackMVA_minMVA=0.955,
    TwoTrackKs_minTrackPt_piKs=445.011,
    TwoTrackKs_minTrackIPChi2_piKs=50,
    TwoTrackKs_minComboPt_Ks=2440.02,
    TwoTrackKs_minEta_Ks=4.2,
    TwoTrackKs_min_combip=0.72,
    DiMuonHighMass_pt=1300,
    DiElectronDisplaced_pt=1100,
    DiElectronDisplaced_ipchi2=4.8,
    DiMuonDisplaced_pt=500,
    DiMuonDisplaced_ipchi2=4.4,
    DiPhotonHighMass_minET=3600,
    TrackMVA_maxGhostProb=0.18,
    TwoTrackMVA_maxGhostProb=0.27,
    LambdaLLDetachedTrack_track_mipchi2=10.5,
    LambdaLLDetachedTrack_combination_bpvfd=23,
    XiOmegaLLL_track_ipchi2=16.5)
