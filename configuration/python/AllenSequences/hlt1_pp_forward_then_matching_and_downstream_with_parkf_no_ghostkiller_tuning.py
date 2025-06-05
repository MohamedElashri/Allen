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
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.get_thresholds import get_thresholds
from AllenConf.matching_reconstruction import make_velo_scifi_matches

from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.validators import mc_data_provider
from AllenConf.odin import decode_odin
from AllenCore.algorithms import reconstructible_signal_counter_t
from AllenConf.utils import initialize_number_of_events
from AllenConf.utils import make_algorithm
from AllenCore.configuration_options import is_allen_standalone

with make_velo_scifi_matches.bind(ghost_killer_threshold=1.):
    hlt1_node = setup_hlt1_node(
        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
        threshold_settings=get_thresholds("tuning"),
        with_ut=True,
        enableTupling=True,
        enableDownstream=True,
        with_fullKF=True)

generate(hlt1_node)
