###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType

hlt1_node = setup_hlt1_node(
    tracking_type=TrackingType.MATCHING_THEN_FORWARD, EnableGEC=False)
generate(hlt1_node)
