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
from AllenConf.velo_reconstruction import make_pr_velo_tracks

with (make_velo_scifi_matches.bind(ghost_killer_threshold=0.8),\
      make_pr_velo_tracks.bind(missing_modules=[21])):
    hlt1_node = setup_hlt1_node(
        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
        with_ut=True,
        with_fullKF=True,
        enableAlignment=
        False,  # Disable alignment lines since this is used during magnet off
        enableDownstream=False,  # Downstream not used in technical lines
        enablePhysics=False,  # Only enable technical lines
        withSMOG2=False,  # Only enable technical lines
        passthrough_pre_scaler=
        1.0  # Special configuration: unprescaled passthrough
    )
generate(hlt1_node)
