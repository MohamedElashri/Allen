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
    TrackMVA_alpha=300,
    TrackMVA_maxGhostProb=0.29,
    TrackElectronMVA_alpha=1800,
    TrackMuonMVA_alpha=-800,
    TrackMuonMVA_maxCorrChi2=1.8,
    D2HH_track_ip=0.07,
    D2HH_track_pt=800,
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=4900.,
    SingleHighPtLepton_pt_noMuonID=4900.,
    TwoTrackMVA_minMVA=0.970,
    TwoTrackMVA_maxGhostProb=0.22,
    TwoTrackKs_minTrackPt_piKs=445.011,
    TwoTrackKs_minTrackIPChi2_piKs=50,
    TwoTrackKs_minComboPt_Ks=2440.02,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=0.72,
    DiMuonHighMass_pt=700,
    DiMuonHighMass_maxCorrChi2=1.8,
    DiMuonDisplaced_pt=500.,
    DiMuonDisplaced_ipchi2=4.4,
    DiMuonDisplaced_maxCorrChi2=1.8,
    DiElectronDisplaced_pt=1000.,
    DiElectronDisplaced_ipchi2=4.8,
    DiPhotonHighMass_minET=3600.,
    LambdaLLDetachedTrack_track_mipchi2=16,
    LambdaLLDetachedTrack_combination_bpvfd=50,
    XiOmegaLLL_track_ipchi2=30.5)
