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
    D2HH_ctIPScale=1,
    D2HH_track_ip=0.075,
    D2HH_track_pt=750,
    DiElectronDisplaced_ipchi2=4.5,
    DiElectronDisplaced_pt=950,
    DiMuonDisplaced_ipchi2=5,
    DiMuonDisplaced_maxCorrChi2=1.8,
    DiMuonDisplaced_pt=550,
    DiMuonHighMass_maxCorrChi2=1.8,
    DiMuonHighMass_pt=550,
    DiPhotonHighMass_minET=3200,
    LambdaLLDetachedTrack_combination_bpvfd=17,
    LambdaLLDetachedTrack_track_mipchi2=19,
    SingleHighPtLepton_pt=12500,
    SingleHighPtLepton_pt_noMuonID=12500,
    TrackElectronMVA_alpha=620,
    TrackMVA_alpha=100,
    TrackMVA_maxGhostProb=0.8,
    TrackMuonMVA_alpha=-680,
    TrackMuonMVA_maxCorrChi2=1.8,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_minComboPt_Ks=2474.17,
    TwoTrackKs_minTrackIPChi2_piKs=50,
    TwoTrackKs_minTrackPt_piKs=459.669,
    TwoTrackKs_min_combip=0.72,
    TwoTrackMVA_maxGhostProb=0.8,
    TwoTrackMVA_minMVA=0.971,
    XiOmegaLLL_track_ipchi2=0)
