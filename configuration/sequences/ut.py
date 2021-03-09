###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.UTSequence import make_ut_tracks
from definitions.InitSequence import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf

velo_sequence = VeloSequence()

ut_sequence = UTSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"],
    host_ut_banks=velo_sequence["host_ut_banks"])


def ut_tracking_leaf(name, **kwargs):
    alg = make_ut_tracks(**kwargs)["dev_ut_track_hits"].producer
    return make_leaf(name, alg=alg)


ut_tracking_sequence = CompositeNode(
    "UTTrackingWithGEC",
    [gec_leaf("gec"), ut_tracking_leaf("ut_tracking")],
    NodeLogic.LAZY_AND,
    forceOrder=True)

generate(ut_tracking_sequence)
