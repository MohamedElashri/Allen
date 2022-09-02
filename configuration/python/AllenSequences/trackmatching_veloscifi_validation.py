###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi, seeding_xz, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.hlt1_reconstruction import make_composite_node_with_gec
from AllenConf.validators import velo_validation, seeding_validation, seeding_xz_validation, long_validation, velo_scifi_dump
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)
velo = velo_validation(velo_tracks)
decoded_scifi = decode_scifi()
seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
seeding_tracks = make_seeding_tracks(decoded_scifi, seeding_xz_tracks)
seed = seeding_validation(seeding_tracks)
seed_xz = seeding_xz_validation()
matched_tracks = make_velo_scifi_matches(velo_tracks, velo_states,
                                         seeding_tracks)
velo_scifi = long_validation(matched_tracks)
velo_scifi_matching_sequence = CompositeNode(
    "Validators", [
        make_composite_node_with_gec(
            "veloValidation", velo, with_scifi=True, with_ut=False),
        make_composite_node_with_gec(
            "veloSciFiDump",
            velo_scifi_dump(matched_tracks),
            with_scifi=True,
            with_ut=False),
        make_composite_node_with_gec(
            "seedingXZValidation", seed_xz, with_scifi=True, with_ut=False),
        make_composite_node_with_gec(
            "seedingValidation", seed, with_scifi=True, with_ut=False),
        make_composite_node_with_gec(
            "veloSciFiValidation", velo_scifi, with_scifi=True, with_ut=False)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(velo_scifi_matching_sequence)
