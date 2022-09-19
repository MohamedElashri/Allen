###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import make_gec
from AllenConf.scifi_reconstruction import forward_tracking
from AllenConf.velo_reconstruction import decode_velo
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    forward_tracking_sequence = CompositeNode(
        "ForwardTrackingWithGEC", [
            make_gec(
                "gec", max_scifi_clusters=2 * 9750, max_ut_clusters=2 * 9750),
            forward_tracking()
        ],
        NodeLogic.LAZY_AND,
        force_order=True)

generate(forward_tracking_sequence)
