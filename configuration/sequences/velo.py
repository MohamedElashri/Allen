###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import make_velo_tracks
from definitions.InitSequence import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf


def velo_tracking_leaf(name, **kwargs):
    alg = make_velo_tracks(**kwargs)["dev_velo_track_hits"].producer
    return make_leaf(name, alg=alg)


def gec_leaf(name,
             min_scifi_ut_clusters="0",
             max_scifi_ut_clusters="9750",
             **kwargs):
    alg = gec(
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)
    return make_leaf(name, alg=alg)


velo_tracking_sequence = CompositeNode(
    "VeloTrackingWithGEC",
    NodeLogic.LAZY_AND,
    [gec_leaf("gec"), velo_tracking_leaf("velo_tracking")],
    forceOrder=True)

generate(velo_tracking_sequence)
