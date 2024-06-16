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
    TrackElectronMVA_alpha=2200,
    TrackMuonMVA_alpha=-400,
    D2HH_track_ip=0.08,
    D2HH_track_pt=800,
    TwoTrackMVA_minMVA=0.975,
    TwoTrackKs_minTrackPt_piKs=1360.6,
    TwoTrackKs_minTrackIPChi2_piKs=167.015,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=2.67015,
    DiMuonHighMass_pt=700,
    DiElectronDisplaced_pt=1000,
    DiElectronDisplaced_ipchi2=6.2,
    DiMuonDisplaced_pt=400,
    DiMuonDisplaced_ipchi2=8.2,
    DiPhotonHighMass_minET=3600,
    LambdaLLDetachedTrack_track_mipchi2=115,
    LambdaLLDetachedTrack_combination_bpvfd=22,
    XiOmegaLLL_track_ipchi2=44.5)
