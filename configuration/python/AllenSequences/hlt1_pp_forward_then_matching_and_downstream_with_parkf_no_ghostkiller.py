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
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.scifi_reconstruction import make_forward_tracks

with (make_velo_scifi_matches.bind(ghost_killer_threshold=1.0),\
      make_forward_tracks.bind(ghost_killer_threshold=1.0)):
    hlt1_node = setup_hlt1_node(
        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
        enableDownstream=True,
        with_fullKF=True)
generate(hlt1_node)
