###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.ut_reconstruction import make_ut_tracks
from AllenConf.persistency import make_gather_selections, make_global_decision
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, make_composite_node_with_gec
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line
from AllenConf.utils import line_maker, make_gec
from AllenConf.validators import (
    velo_validation, veloUT_validation, long_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation)

from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

# Reconstructed objects
with make_ut_tracks.bind(restricted=False):
    non_restricted_hlt1_reconstruction = hlt1_reconstruction(
        algorithm_name='hlt1_complex_validation_non_restricted_sequence')

restricted_hlt1_reconstruction = hlt1_reconstruction(
    algorithm_name='hlt1_complex_validation_restricted_sequence')
gec = make_gec(count_scifi=True, count_ut=True)

lines = []
with line_maker.bind(prefilter=gec):
    lines.append(
        line_maker(
            make_track_mva_line(
                restricted_hlt1_reconstruction["long_tracks"],
                restricted_hlt1_reconstruction["long_track_particles"],
                name="Hlt1TrackMVA_Restricted")))
    lines.append(
        line_maker(
            make_two_track_mva_line(
                restricted_hlt1_reconstruction["long_tracks"],
                restricted_hlt1_reconstruction["dihadron_secondary_vertices"],
                name="Hlt1TwoTrackMVA_Restricted")))
    lines.append(
        line_maker(
            make_track_mva_line(
                non_restricted_hlt1_reconstruction["long_tracks"],
                non_restricted_hlt1_reconstruction["long_track_particles"],
                name="Hlt1TrackMVA_Non_Restricted")))
    lines.append(
        line_maker(
            make_two_track_mva_line(
                non_restricted_hlt1_reconstruction["long_tracks"],
                non_restricted_hlt1_reconstruction[
                    "dihadron_secondary_vertices"],
                name="Hlt1TwoTrackMVA_Non_Restricted")))

# list of line algorithms, required for the gather selection and DecReport algorithms
line_algorithms = [tup[0] for tup in lines]

# lost of line nodes, required to set up the CompositeNode
line_nodes = [tup[1] for tup in lines]

lines_leaf = CompositeNode(
    "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

hlt1_leaf = CompositeNode(
    "Allen", [
        lines_leaf,
        make_global_decision(lines=line_algorithms),
        rate_validation(line_algorithms)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

validators_leaf = CompositeNode(
    "Validators", [
        make_composite_node_with_gec(
            "velo_validator",
            velo_validation(restricted_hlt1_reconstruction["velo_tracks"]),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "restricted_veloUT_validator",
            veloUT_validation(restricted_hlt1_reconstruction["ut_tracks"],
                              "restricted_veloUT_validator"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "non-restricted_veloUT_validator",
            veloUT_validation(non_restricted_hlt1_reconstruction["ut_tracks"],
                              "non-restricted_veloUT_validator"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "restricted_long_validator",
            long_validation(restricted_hlt1_reconstruction["long_tracks"],
                            "restricted_long_validator"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "non-restricted_long_validator",
            long_validation(non_restricted_hlt1_reconstruction["long_tracks"],
                            "non-restricted_long_validator"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "restricted_muon_validation",
            muon_validation(restricted_hlt1_reconstruction["muonID"],
                            "restricted_muon_validation"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "non-restricted_muon_validation",
            muon_validation(non_restricted_hlt1_reconstruction["muonID"],
                            "non-restricted_muon_validation"),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "pv_validation",
            pv_validation(restricted_hlt1_reconstruction["pvs"]),
            with_scifi=True,
            with_ut=True),
        make_composite_node_with_gec(
            "restricted_kalman_validation",
            kalman_validation(
                restricted_hlt1_reconstruction["kalman_velo_only"],
                "restricted_kalman_validation"),
            with_scifi=True,
            with_ut=True)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=False)

node = CompositeNode(
    "AllenWithValidators", [hlt1_leaf, validators_leaf],
    NodeLogic.NONLAZY_AND,
    force_order=False)

generate(node)
