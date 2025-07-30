###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi, seeding_xz, make_seeding_XZ_tracks, make_seeding_tracks
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
        CompositeNode(
            "seedingXZValidation", [seed_xz],
            NodeLogic.LAZY_AND,
            force_order=True),
        CompositeNode(
            "seedingValidation", [seed], NodeLogic.LAZY_AND, force_order=True)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(seeding_sequence)
