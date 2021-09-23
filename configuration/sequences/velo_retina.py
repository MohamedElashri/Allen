###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import velo_tracking
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate
from AllenConf.velo_reconstruction import decode_velo

with decode_velo.bind(retina_decoding="True"):
    velo_tracking_sequence = CompositeNode(
        "VeloTrackingWithGEC", [gec("gec"), velo_tracking()],
        NodeLogic.LAZY_AND,
        force_order=True)

generate(velo_tracking_sequence)
