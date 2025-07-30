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
    TrackMVA_alpha=-10000.,
    TrackMVA_maxGhostProb=0.5,
    TrackElectronMVA_alpha=-10000.,
    TrackMuonMVA_alpha=-10000.,
    TrackMuonMVA_maxCorrChi2=10,
    D2HH_track_ip=0.,
    D2HH_track_pt=0.,
    D2HH_ctIPScale=1.,
    SingleHighPtLepton_pt=0.,
    SingleHighPtLepton_pt_noMuonID=0.,
    TwoTrackMVA_minMVA=0.0,
    TwoTrackMVA_maxGhostProb=0.5,
    TwoTrackKs_minTrackPt_piKs=0.,
    TwoTrackKs_minTrackIPChi2_piKs=0.,
    TwoTrackKs_minComboPt_Ks=0.,
    TwoTrackKs_maxEta_Ks=5.,
    TwoTrackKs_min_combip=0.,
    DiMuonHighMass_pt=0.,
    DiMuonHighMass_maxCorrChi2=10.,
    DiMuonDisplaced_pt=0.,
    DiMuonDisplaced_ipchi2=0.,
    DiMuonDisplaced_maxCorrChi2=10.,
    DiElectronDisplaced_pt=0.,
    DiElectronDisplaced_ipchi2=0.,
    DiPhotonHighMass_minET=0.,
    TrackMuonMVA_NN=0.,
    DiMuonDisplaced_NN=0.,
    DiMuonDisplacedSoftPT_NN=0.,
    DiElectronDisplaced_NN=0.,
    TrackElectronMVA_NN=0.,
    DiMuonHighMass_NN=0.,
    DiMuonNoIP_NN=0.,
    DownstreamKsToPiPi_minMVA_detached=0.55,
    DownstreamLambdaToPPi_minMVA_detached=0.5)
