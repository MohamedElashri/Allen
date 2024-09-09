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
    DiMuonDisplaced_pt=600,
    DiMuonHighMass_maxCorrChi2=1.8,
    DiMuonHighMass_pt=600,
    DiPhotonHighMass_minET=3400,
    LambdaLLDetachedTrack_combination_bpvfd=47,
    LambdaLLDetachedTrack_track_mipchi2=19,
    SingleHighPtLepton_pt=12500,
    SingleHighPtLepton_pt_noMuonID=12500,
    TrackElectronMVA_alpha=720,
    TrackMVA_alpha=140,
    TrackMVA_maxGhostProb=0.8,
    TrackMuonMVA_alpha=-740,
    TrackMuonMVA_maxCorrChi2=1.8,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_minTrackIPChi2_piKs=51.0976,
    TwoTrackKs_minTrackPt_piKs=480.976,
    TwoTrackKs_min_combip=0.864887,
    TwoTrackMVA_maxGhostProb=0.8,
    TwoTrackMVA_minMVA=0.97,
    XiOmegaLLL_track_ipchi2=0)
