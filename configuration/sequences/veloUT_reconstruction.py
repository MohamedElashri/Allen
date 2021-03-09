###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.velo_reconstruction import decode_velo, make_velo_tracks
from definitions.ut_reconstruction import decode_ut, make_ut_tracks
from definitions.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.event_list_utils import generate, make_leaf


def gec_leaf(name, min_scifi_ut_clusters="0", max_scifi_ut_clusters="9750"):
    alg = gec(
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)
    return make_leaf(name, alg=alg)


def ut_tracking_leaf(name):
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    alg = ut_tracks["dev_ut_track_hits"].producer
    return make_leaf(name, alg=alg)


ut_tracking_sequence = CompositeNode(
    "UTTrackingWithGEC",
    [gec_leaf("gec"), ut_tracking_leaf("ut_tracking")],
    NodeLogic.LAZY_AND,
    forceOrder=True)

generate(ut_tracking_sequence)
