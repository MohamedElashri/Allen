###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType

hlt1_node = setup_hlt1_node(
    withMCChecking=True,
    tracking_type=TrackingType.MATCHING,
    with_calo=False,
    with_muon=False,
    with_ut=False)
generate(hlt1_node)
