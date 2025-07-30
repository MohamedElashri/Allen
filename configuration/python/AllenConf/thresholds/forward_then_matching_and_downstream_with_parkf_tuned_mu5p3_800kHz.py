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
    TrackMVA_alpha=720,
    TrackElectronMVA_alpha=2220,
    TrackElectronMVA_NN=0.6,
    TrackMuonMVA_alpha=-80,
    TrackMuonMVA_NN=0.4,
    D2HH_track_ip=0.08,
    D2HH_track_pt=900,
    TwoTrackMVA_minMVA=0.98,
    TwoTrackKs_minTrackPt_piKs=1360.6,
    TwoTrackKs_minTrackIPChi2_piKs=167.015,
    TwoTrackKs_minComboPt_Ks=2500,
    TwoTrackKs_maxEta_Ks=4.2,
    TwoTrackKs_min_combip=2.67015,
    DiMuonHighMass_pt=1200,
    DiMuonHighMass_NN=0.4,
    DiElectronDisplaced_pt=650,
    DiElectronDisplaced_ipchi2=10,
    DiElectronDisplaced_NN=0.6,
    DiMuonDisplaced_pt=380,
    DiMuonDisplaced_ipchi2=8.88,
    DiMuonDisplaced_NN=0.4,
    DiPhotonHighMass_minET=3500,
    TrackMVA_maxGhostProb=0.8,
    TwoTrackMVA_maxGhostProb=0.8,
    DownstreamKsToPiPi_minMVA_detached=0.55,
    DownstreamLambdaToPPi_minMVA_detached=0.5,
    DownstreamTwoTrackKs_minTrackPt_piKs=1450,
    DiProtonHighMass_P_minPt=5000,
    DiProtonHighMass_PP_minPt=6500,
    DownstreamGammaToEE_minPt=1250,
)
