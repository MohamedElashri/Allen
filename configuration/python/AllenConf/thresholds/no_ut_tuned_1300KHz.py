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
    TrackMVA_alpha=0,
    TrackElectronMVA_alpha=2200,
    TrackMuonMVA_alpha=-700,
    D2HH_track_ip=0.07,
    D2HH_track_pt=700,
    SingleHighPtLepton_pt=4700,
    SingleHighPtLepton_pt_noMuonID=4700,
    TwoTrackMVA_minMVA=0.96,
    TwoTrackKs_minTrackPt_piKs=425,
    TwoTrackKs_minTrackIPChi2_piKs=47.8919,
    TwoTrackKs_minComboPt_Ks=2250.1,
    TwoTrackKs_maxEta_Ks=4.2371,
    TwoTrackKs_min_combip=0.686271,
    DiMuonHighMass_pt=700,
    DiElectronDisplaced_pt=700,
    DiElectronDisplaced_ipchi2=7,
    DiMuonDisplaced_pt=300,
    DiMuonDisplaced_ipchi2=5.6,
    DiPhotonHighMass_minET=3100,
    TrackMVA_maxGhostProb=0.1,
    TwoTrackMVA_maxGhostProb=0.235,
    LambdaLLDetachedTrack_track_mipchi2=30,
    LambdaLLDetachedTrack_combination_bpvfd=26,
    XiOmegaLLL_track_ipchi2=30.5)
