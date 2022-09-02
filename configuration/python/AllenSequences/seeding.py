###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import seeding
from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

seeding_sequence = CompositeNode(
    "Seeding", [make_gec("gec", count_ut=False),
                seeding()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(seeding_sequence)
