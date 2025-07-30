###############################################################################
# (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.get_thresholds import get_thresholds
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.velo_reconstruction import make_pr_velo_tracks, decode_velo
from AllenConf.hlt1_calibration_lines import make_pi02gammagamma_line

#
# HLT1 pp default sequence (veloSP) + (100%) pi02gammagamma
# This is a special sequence to pre_scaler=1. in pi02gammagamma line for pi0 calibration
#
with decode_velo.bind(retina_decoding=False), make_velo_scifi_matches.bind(
        ghost_killer_threshold=0.8), make_pr_velo_tracks.bind(
            missing_modules=[21]), make_pi02gammagamma_line.bind(
                pre_scaler=1.):
    hlt1_node = setup_hlt1_node(
        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
        threshold_settings=get_thresholds(
            "forward_then_matching_tuned_mu5p3_1200KHz"),
        with_fullKF=True,
        with_ut=True,
        enableDownstream=True)

generate(hlt1_node)
