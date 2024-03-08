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
    alpha: float
    alpha_electron: float
    alpha_muon: float
    charm_track_ip: float
    charm_track_pt: float
    ctIPScale: float
    singleMinPt: float
    singleMinPt_noMuonID: float
    minMVA: float
    minTrackPt_piKs: float
    minTrackIPChi2_piKs: float
    minComboPt_Ks: float
    minEta_Ks: float
    min_combip: float
    highmass_dimuon_pt: float
    displaced_dimuon_pt: float
    displaced_dimuon_ipchi2: float
    displaced_dielectron_pt: float
    displaced_dielectron_ipchi2: float
    diphoton_minET: float


def get_thresholds(threshold_setting_name):
    settings_default = Thresholds(
        alpha=296.,
        alpha_electron=0.,
        alpha_muon=0.,
        charm_track_ip=0.06,
        charm_track_pt=800.,
        ctIPScale=1.,
        singleMinPt=6000.,
        singleMinPt_noMuonID=8000.,
        minMVA=0.9569,
        minTrackPt_piKs=470.,
        minTrackIPChi2_piKs=50.,
        minComboPt_Ks=2500.,
        minEta_Ks=4.2,
        min_combip=0.72,
        highmass_dimuon_pt=300,
        displaced_dimuon_pt=500,
        displaced_dimuon_ipchi2=5,
        displaced_dielectron_pt=500,
        displaced_dielectron_ipchi2=5,
        diphoton_minET=2500)

    settings_tuning = Thresholds(
        alpha=-10000.,
        alpha_electron=-10000.,
        alpha_muon=-10000.,
        charm_track_ip=0.,
        charm_track_pt=0.,
        ctIPScale=1.,
        singleMinPt=0.,
        singleMinPt_noMuonID=0.,
        minMVA=0.0,
        minTrackPt_piKs=0.,
        minTrackIPChi2_piKs=0.,
        minComboPt_Ks=0.,
        minEta_Ks=5.,
        min_combip=0.,
        highmass_dimuon_pt=0.,
        displaced_dimuon_pt=0.,
        displaced_dimuon_ipchi2=0.,
        displaced_dielectron_pt=0.,
        displaced_dielectron_ipchi2=0.,
        diphoton_minET=0.)

    settings_1MHz = Thresholds(
        alpha=10200,
        alpha_electron=2700,
        alpha_muon=-300,
        charm_track_ip=0.07,
        charm_track_pt=1000,
        ctIPScale=1.,
        singleMinPt=5000.,
        singleMinPt_noMuonID=5000.,
        minMVA=0.975,
        minTrackPt_piKs=1369.65,
        minTrackIPChi2_piKs=163.632,
        minComboPt_Ks=2496.02,
        minEta_Ks=4.20796,
        min_combip=2.64746,
        highmass_dimuon_pt=1200.,
        displaced_dimuon_pt=700.,
        displaced_dimuon_ipchi2=7.5,
        displaced_dielectron_pt=1000.,
        displaced_dielectron_ipchi2=8.,
        diphoton_minET=4000.)

    if threshold_setting_name == "default": return settings_default
    elif threshold_setting_name == "tuning": return settings_tuning
    elif threshold_setting_name == "no_ut_tuned_1MHz": return settings_1MHz
    else:
        print(
            f"Error: {threshold_setting_name} not a valid set of threshold settings"
        )
