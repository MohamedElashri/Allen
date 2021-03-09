###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.velo_reconstruction import decode_velo, make_velo_tracks
from definitions.primary_vertex_reconstruction import make_pvs
from definitions.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.event_list_utils import generate, make_leaf


def gec_leaf(name, min_scifi_ut_clusters="0", max_scifi_ut_clusters="9750"):
    alg = gec(
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)
    return make_leaf(name, alg=alg)


def pv_finder_leaf(name):
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    pvs = make_pvs(velo_tracks)
    alg = pvs["dev_multi_final_vertices"].producer
    return make_leaf(name, alg=alg)


pv_finder_sequence = CompositeNode(
    "PVWithGEC",
    [gec_leaf("gec"), pv_finder_leaf("pv_finder")],
    NodeLogic.LAZY_AND,
    forceOrder=True)

generate(pv_finder_sequence)
