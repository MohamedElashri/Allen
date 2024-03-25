###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.utils import make_tae_activity_filter

with decode_velo.bind(retina_decoding=False):
    with make_tae_activity_filter.bind(
            use_long_tracks=False, name="tae_velo_activity_filter"):
        hlt1_node = setup_hlt1_node(
            tracking_type=TrackingType.FORWARD_THEN_MATCHING,
            with_ut=False,
            tae_activity=True)
generate(hlt1_node)
