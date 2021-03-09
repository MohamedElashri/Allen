###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.velo_reconstruction import decode_velo, make_velo_tracks
from definitions.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf


def velo_tracking_leaf(name):
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    alg = velo_tracks["dev_velo_track_hits"].producer
    return make_leaf(name, alg=alg)


def gec_leaf(name, min_scifi_ut_clusters="0", max_scifi_ut_clusters="9750"):
    alg = gec(
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)
    return make_leaf(name, alg=alg)


velo_tracking_sequence = CompositeNode(
    "VeloTrackingWithGEC",
    [gec_leaf("gec"), velo_tracking_leaf("velo_tracking")],
    NodeLogic.LAZY_AND,
    forceOrder=True)

generate(velo_tracking_sequence)
