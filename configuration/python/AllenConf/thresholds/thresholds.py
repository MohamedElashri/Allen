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
from typing import NamedTuple


class Thresholds(NamedTuple):
    TrackMVA_alpha: float
    TrackElectronMVA_alpha: float
    TrackMuonMVA_alpha: float
    TrackMuonMVA_maxCorrChi2: float
    TrackMVA_maxGhostProb: float
    D2HH_track_ip: float
    D2HH_track_pt: float
    D2HH_ctIPScale: float
    SingleHighPtLepton_pt: float
    SingleHighPtLepton_pt_noMuonID: float
    TwoTrackMVA_minMVA: float
    TwoTrackMVA_maxGhostProb: float
    TwoTrackKs_minTrackPt_piKs: float
    TwoTrackKs_minTrackIPChi2_piKs: float
    TwoTrackKs_minComboPt_Ks: float
    TwoTrackKs_maxEta_Ks: float
    TwoTrackKs_min_combip: float
    DiMuonHighMass_pt: float
    DiMuonDisplaced_pt: float
    DiMuonDisplaced_ipchi2: float
    DiMuonDisplaced_maxCorrChi2: float
    DiElectronDisplaced_pt: float
    DiElectronDisplaced_ipchi2: float
    DiPhotonHighMass_minET: float
    LambdaLLDetachedTrack_track_mipchi2: float
    LambdaLLDetachedTrack_combination_bpvfd: float
    XiOmegaLLL_track_ipchi2: float
