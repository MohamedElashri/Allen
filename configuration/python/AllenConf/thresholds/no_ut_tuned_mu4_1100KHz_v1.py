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
    DiMuonHighMass_maxCorrChi2=1.8,
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=12500,
    SingleHighPtLepton_pt_noMuonID=12500,
    TrackMVA_maxGhostProb=0.2,
    TwoTrackMVA_maxGhostProb=0.2,
    TrackMVA_alpha=400,
    TrackElectronMVA_alpha=1600,
    TrackMuonMVA_alpha=-800,
    D2HH_track_ip=0.08,
    D2HH_track_pt=700,
    TwoTrackMVA_minMVA=0.96,
    TwoTrackKs_minTrackPt_piKs=429.164,
    TwoTrackKs_minTrackIPChi2_piKs=50,
    TwoTrackKs_minComboPt_Ks=2408.33,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=0.72,
    DiMuonHighMass_pt=600,
    DiElectronDisplaced_pt=800,
    DiElectronDisplaced_ipchi2=7.4,
    DiMuonDisplaced_pt=400,
    DiMuonDisplaced_ipchi2=5.6,
    DiPhotonHighMass_minET=2700,
    LambdaLLDetachedTrack_track_mipchi2=115,
    LambdaLLDetachedTrack_combination_bpvfd=22,
    XiOmegaLLL_track_ipchi2=15)
