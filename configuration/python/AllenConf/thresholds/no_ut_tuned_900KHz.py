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
    DiMuonHighMass_maxCorrChi2=1.8,
    DiMuonDisplaced_maxCorrChi2=1.8,
    D2HH_ctIPScale=1.,
    TrackMVA_alpha=400,
    TrackElectronMVA_alpha=2900,
    TrackMuonMVA_alpha=-500,
    D2HH_track_ip=0.08,
    D2HH_track_pt=700,
    SingleHighPtLepton_pt=5000,
    SingleHighPtLepton_pt_noMuonID=5000,
    TwoTrackMVA_minMVA=0.97,
    TwoTrackKs_minTrackPt_piKs=480.976,
    TwoTrackKs_minTrackIPChi2_piKs=51.0976,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=0.864887,
    DiMuonHighMass_pt=700,
    DiElectronDisplaced_pt=700,
    DiElectronDisplaced_ipchi2=8.8,
    DiMuonDisplaced_pt=300,
    DiMuonDisplaced_ipchi2=8,
    DiPhotonHighMass_minET=3600,
    TrackMVA_maxGhostProb=0.1,
    TwoTrackMVA_maxGhostProb=0.1,
    LambdaLLDetachedTrack_track_mipchi2=19.5,
    LambdaLLDetachedTrack_combination_bpvfd=50,
    XiOmegaLLL_track_ipchi2=30.5)
