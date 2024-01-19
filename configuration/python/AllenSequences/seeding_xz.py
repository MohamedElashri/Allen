###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import seeding_xz
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

seeding_sequence = CompositeNode(
    "Seeding_XZ", [seeding_xz()], NodeLogic.LAZY_AND, force_order=True)

generate(seeding_sequence)
