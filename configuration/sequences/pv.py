###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.primary_vertex_reconstruction import pv_finder
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

pv_finder_sequence = CompositeNode(
    "PVWithGEC", [gec("gec"), pv_finder()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(pv_finder_sequence)
