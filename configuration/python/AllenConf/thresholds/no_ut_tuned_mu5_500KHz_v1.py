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

hold_settings = Thresholds(
    TrackMuonMVA_maxCorrChi2=1.8,
    DiMuonDisplaced_maxCorrChi2=1.8,
    DiMuonHighMass_maxCorrChi2=1.8,
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=12500,
    SingleHighPtLepton_pt_noMuonID=12500,
    TrackMVA_maxGhostProb=0.2,
    TwoTrackMVA_maxGhostProb=0.2,
    TrackMVA_alpha=10200,
    TrackElectronMVA_alpha=4700,
    TrackMuonMVA_alpha=300,
    D2HH_track_ip=0.07,
    D2HH_track_pt=1300,
    TwoTrackMVA_minMVA=0.985,
    TwoTrackKs_minTrackPt_piKs=1360.6,
    TwoTrackKs_minTrackIPChi2_piKs=167.015,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=2.67015,
    DiMuonHighMass_pt=1000,
    DiElectronDisplaced_pt=1000,
    DiElectronDisplaced_ipchi2=10,
    DiMuonDisplaced_pt=600,
    DiMuonDisplaced_ipchi2=9.4,
    DiPhotonHighMass_minET=4800,
    LambdaLLDetachedTrack_track_mipchi2=58,
    LambdaLLDetachedTrack_combination_bpvfd=36,
    XiOmegaLLL_track_ipchi2=24)
