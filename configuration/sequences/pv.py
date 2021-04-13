###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate


def pv_finder():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    pvs = make_pvs(velo_tracks)
    alg = pvs["dev_multi_final_vertices"].producer
    return alg


pv_finder_sequence = CompositeNode(
    "PVWithGEC", [gec("gec"), pv_finder()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(pv_finder_sequence)
