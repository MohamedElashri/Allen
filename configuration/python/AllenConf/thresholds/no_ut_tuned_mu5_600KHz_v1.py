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
    TrackMVA_alpha=10200,
    TrackElectronMVA_alpha=2700,
    TrackMuonMVA_alpha=-500,
    D2HH_track_ip=0.07,
    D2HH_track_pt=1000,
    TwoTrackMVA_minMVA=0.985,
    TwoTrackKs_minTrackPt_piKs=762.889,
    TwoTrackKs_minTrackIPChi2_piKs=76.6865,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=1.38,
    DiMuonHighMass_pt=800,
    DiElectronDisplaced_pt=1000,
    DiElectronDisplaced_ipchi2=7.2,
    DiMuonDisplaced_pt=400,
    DiMuonDisplaced_ipchi2=9.8,
    DiPhotonHighMass_minET=4400,
    LambdaLLDetachedTrack_track_mipchi2=181,
    LambdaLLDetachedTrack_combination_bpvfd=7,
    XiOmegaLLL_track_ipchi2=26)
