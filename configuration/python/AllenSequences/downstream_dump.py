###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.ut_reconstruction import decode_ut
from AllenConf.validators import velo_validation, seeding_validation, seeding_xz_validation, long_validation, downstream_dump
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.utils import make_gec
from AllenCore.generator import generate
from AllenConf.downstream_reconstruction import make_downstream

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
decoded_ut = decode_ut()
downstream_tracks = make_downstream(
    decoded_ut, seeding_tracks, matched_tracks, ghost_killer_threshold=1.)
downstream_dump_alg = downstream_dump(
    downstream_tracks,
    dump_scifi=False,
    dump_ut_hits=False,
    dump_downstream=True,
    dump_mcps=False,
    output_folder='/dump_output')

downstream_dump_sequence = CompositeNode(
    "DownstreamDump", [make_gec("gec"), downstream_dump_alg],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(downstream_dump_sequence)
