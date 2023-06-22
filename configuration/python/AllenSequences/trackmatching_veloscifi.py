###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.matching_reconstruction import velo_scifi_matching
from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

velo_scifi_matching_sequence = CompositeNode(
    "Matching", [
        make_gec("gec", count_ut=False),
        velo_scifi_matching(algorithm_name='velo_scifi_matching_sequence')
    ],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(velo_scifi_matching_sequence)
