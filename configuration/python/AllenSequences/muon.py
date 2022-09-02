###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import make_gec
from AllenConf.muon_reconstruction import muon_id
from AllenCore.generator import generate
from PyConf.control_flow import NodeLogic, CompositeNode

muon_id_sequence = CompositeNode(
    "MuonIDWithGEC", [make_gec("gec"), muon_id()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(muon_id_sequence)
