###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi, seeding_xz, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.hlt1_reconstruction import make_composite_node_with_gec
from AllenConf.validators import seeding_validation, seeding_xz_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decoded_scifi = decode_scifi()
seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
seeding_tracks = make_seeding_tracks(
    decoded_scifi,
    seeding_xz_tracks,
    scifi_consolidate_seeds_name='seeding_sequence_scifi_consolidate_seeds')
seed = seeding_validation(seeding_tracks)
seed_xz = seeding_xz_validation()
seeding_sequence = CompositeNode(
    "Validators", [
        make_composite_node_with_gec(
            "seedingXZValidation", seed_xz, with_scifi=True, with_ut=False),
        make_composite_node_with_gec(
            "seedingValidation", seed, with_scifi=True, with_ut=False)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(seeding_sequence)
