###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.InitSequence import gec
from definitions.ForwardSequence import make_forward_tracks
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf

velo_sequence = VeloSequence()

ut_sequence = UTSequence(
    initialize_lists=velo_sequence['initialize_lists'],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"],
    host_ut_banks=velo_sequence["host_ut_banks"])

forward_sequence = ForwardSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

def forward_tracking_leaf(name, **kwargs):
    alg = make_forward_tracks(**kwargs)["dev_scifi_track_hits"].producer
    return make_leaf(name, alg=alg)


forward_tracking_sequence = CompositeNode(
    "ForwardTrackingWithGEC",
    [gec_leaf("gec"),
     forward_tracking_leaf("forward_tracking")],
    NodeLogic.LAZY_AND,
    forceOrder=True)

generate(forward_tracking_sequence)
