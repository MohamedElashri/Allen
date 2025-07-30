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
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.matching_reconstruction import make_velo_scifi_matches
from AllenConf.downstream_reconstruction import make_downstream
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.validators import velo_validation, seeding_validation, seeding_xz_validation, seeding_unmatched_validation, downstream_validation, long_validation
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.primary_vertex_reconstruction import make_pvs

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
unmatched_seed = seeding_unmatched_validation(seeding_tracks, matched_tracks)

decoded_ut = decode_ut()
# ut_tracks = make_ut_tracks(decoded_ut=decoded_ut, velo_tracks=velo_tracks)
downstream_tracks = make_downstream(
    decoded_ut=decoded_ut,
    scifi_seeds=seeding_tracks,
    pvs=make_pvs(velo_tracks=velo_tracks),
    # ut_tracks=ut_tracks,
    velo_scifi_matches=matched_tracks)
velo_scifi = long_validation(matched_tracks)
downstream = downstream_validation(downstream_tracks)

downstream_validation_sequence = CompositeNode(
    "Validators", [seed, unmatched_seed, velo_scifi, downstream],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(downstream_validation_sequence)
