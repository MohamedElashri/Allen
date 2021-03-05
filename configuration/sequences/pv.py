###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.PVSequence import make_pvs
from definitions.InitSequence import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from definitions.event_list_utils import generate, make_leaf

velo_sequence = VeloSequence()

pv_sequence = PVSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])


def pv_finder_leaf(name, **kwargs):
    alg = make_pvs(**kwargs)["dev_multi_final_vertices"].producer
    return make_leaf(name, alg=alg)


pv_finder_sequence = CompositeNode(
    "PVWithGEC",
    NodeLogic.LAZY_AND,
    [gec_leaf("gec"), pv_finder_leaf("pv_finder")],
    forceOrder=True)

generate(pv_finder_sequence)
