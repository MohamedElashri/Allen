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
    TrackMVA_alpha=296.,
    TrackMVA_maxGhostProb=0.5,
    TrackElectronMVA_alpha=0.,
    TrackMuonMVA_alpha=0.,
    TrackMuonMVA_maxCorrChi2=1.8,
    D2HH_track_ip=0.06,
    D2HH_track_pt=800.,
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=6000.,
    SingleHighPtLepton_pt_noMuonID=8000.,
    TwoTrackMVA_minMVA=0.9569,
    TwoTrackMVA_maxGhostProb=0.5,
    TwoTrackKs_minTrackPt_piKs=470.,
    TwoTrackKs_minTrackIPChi2_piKs=50.,
    TwoTrackKs_minComboPt_Ks=2500.,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=0.72,
    DiMuonHighMass_pt=300,
    DiMuonHighMass_maxCorrChi2=10.,
    DiMuonDisplaced_pt=500,
    DiMuonDisplaced_ipchi2=5,
    DiMuonDisplaced_maxCorrChi2=10.,
    DiElectronDisplaced_pt=500,
    DiElectronDisplaced_ipchi2=5,
    DiPhotonHighMass_minET=2500,
    LambdaLLDetachedTrack_track_mipchi2=9,
    LambdaLLDetachedTrack_combination_bpvfd=1.4,
    XiOmegaLLL_track_ipchi2=9,
    TrackElectronMVA_NN=0.6,
    TrackMuonMVA_NN=0.4,
    DiMuonHighMass_NN=0.4,
    DiElectronDisplaced_NN=0.6,
    DiMuonDisplaced_NN=0.4,
    DiMuonDisplacedSoftPT_NN=0.8,
    DiMuonNoIP_NN=0.95,
    DownstreamKsToPiPi_minMVA_detached=0.55,
    DownstreamLambdaToPPi_minMVA_detached=0.5)
