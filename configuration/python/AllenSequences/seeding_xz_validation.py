###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi, seeding_xz, make_seeding_XZ_tracks
from AllenConf.validators import seeding_xz_validation
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

seed_xz = seeding_xz_validation()
seeding_sequence = CompositeNode(
    "SeedingXZValidation", [gec("gec"), seed_xz],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(seeding_sequence)
