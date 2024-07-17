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
    TrackMVA_alpha=800,
    TrackElectronMVA_alpha=2500,
    TrackMuonMVA_alpha=0,
    D2HH_track_ip=0.06,
    D2HH_track_pt=1100,
    TwoTrackMVA_minMVA=0.975,
    TwoTrackKs_minTrackPt_piKs=480.976,
    TwoTrackKs_minTrackIPChi2_piKs=51.0976,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=0.864887,
    DiMuonHighMass_pt=700,
    DiElectronDisplaced_pt=900,
    DiElectronDisplaced_ipchi2=8.8,
    DiMuonDisplaced_pt=400,
    DiMuonDisplaced_ipchi2=8.8,
    DiPhotonHighMass_minET=3500,
    LambdaLLDetachedTrack_track_mipchi2=48,
    LambdaLLDetachedTrack_combination_bpvfd=25,
    XiOmegaLLL_track_ipchi2=26.5)
