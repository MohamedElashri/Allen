###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate


def velo_tracking():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    alg = velo_tracks["dev_velo_track_hits"].producer
    return alg


velo_tracking_sequence = CompositeNode(
    "VeloTrackingWithGEC", [gec("gec"), velo_tracking()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(velo_tracking_sequence)
