###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.hlt1_calibration_lines import make_pi02gammagamma_line

with make_pi02gammagamma_line.bind(pre_scaler=1):
    hlt1_node = setup_hlt1_node(
        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
        with_ut=False,
        EnableGEC=False)
generate(hlt1_node)
