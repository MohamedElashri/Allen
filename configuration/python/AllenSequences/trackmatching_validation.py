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
from AllenConf.ut_reconstruction import decode_ut
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.validators import velo_validation, seeding_validation, seeding_xz_validation, long_validation, velo_scifi_dump
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decoded_velo = decode_velo()
ut_hits = decode_ut()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)
velo = velo_validation(velo_tracks)
decoded_scifi = decode_scifi()
seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
seeding_tracks = make_seeding_tracks(
    decoded_scifi,
    seeding_xz_tracks,
    scifi_consolidate_seeds_name=
    'velo_scifi_matching_sequence_scifi_consolidate_seeds')
seed = seeding_validation(seeding_tracks)
seed_xz = seeding_xz_validation()
matched_tracks = make_velo_scifi_matches(
    velo_tracks,
    velo_states,
    seeding_tracks,
    ut_hits=ut_hits,
    matching_consolidate_tracks_name=
    'velo_scifi_matching_sequence_matching_consolidate_tracks')
velo_scifi = long_validation(matched_tracks)
velo_scifi_matching_sequence = CompositeNode(
    "Validators", [
        CompositeNode(
            "veloValidation", [velo], NodeLogic.LAZY_AND, force_order=True),
        CompositeNode(
            "veloSciFiDump", [velo_scifi_dump(matched_tracks)],
            NodeLogic.LAZY_AND,
            force_order=True),
        CompositeNode(
            "seedingXZValidation", [seed_xz],
            NodeLogic.LAZY_AND,
            force_order=True),
        CompositeNode(
            "seedingValidation", [seed], NodeLogic.LAZY_AND, force_order=True),
        CompositeNode(
            "veloSciFiValidation", [velo_scifi],
            NodeLogic.LAZY_AND,
            force_order=True)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(velo_scifi_matching_sequence)
