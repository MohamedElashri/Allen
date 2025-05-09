###############################################################################
# (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           #
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
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=12500,
    SingleHighPtLepton_pt_noMuonID=12500,
    DiMuonDisplacedSoftPT_NN=0.87,
    TrackMVA_alpha=180,
    TrackElectronMVA_alpha=1340,
    TrackElectronMVA_NN=0.6,
    TrackMuonMVA_alpha=-540,
    TrackMuonMVA_NN=0.4,
    D2HH_track_ip=0.09,
    D2HH_track_pt=700,
    TwoTrackMVA_minMVA=0.972,
    TwoTrackKs_minTrackPt_piKs=1036.56,
    TwoTrackKs_minTrackIPChi2_piKs=80,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=1.90044,
    DiMuonHighMass_pt=900,
    DiMuonHighMass_NN=0.4,
    DiElectronDisplaced_pt=560,
    DiElectronDisplaced_ipchi2=8.24,
    DiElectronDisplaced_NN=0.6,
    DiMuonDisplaced_pt=380,
    DiMuonDisplaced_ipchi2=6.64,
    DiMuonDisplaced_NN=0.4,
    DiPhotonHighMass_minET=3000,
    TrackMVA_maxGhostProb=0.8,
    TwoTrackMVA_maxGhostProb=0.8,
    DownstreamKsToPiPi_minMVA_detached=0.55,
    DownstreamLambdaToPPi_minMVA_detached=0.5,
    DownstreamTwoTrackKs_minTrackPt_piKs=550,
    DiProtonHighMass_P_minPt=5000,
    DiProtonHighMass_PP_minPt=6500,
    DownstreamGammaToEE_minPt=1250,
)
