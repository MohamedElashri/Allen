###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import gec
from AllenConf.ut_reconstruction import make_ut_tracks
from AllenConf.persistency import make_gather_selections, make_global_decision
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, make_composite_node_with_gec
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line
from AllenConf.HLT1 import line_maker
from AllenConf.validators import (
    velo_validation, veloUT_validation, forward_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation)

from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

# Reconstructed objects
with make_ut_tracks.bind(restricted=False):
    non_restricted_hlt1_reconstruction = hlt1_reconstruction()

restricted_hlt1_reconstruction = hlt1_reconstruction()

lines = []
lines.append(
    line_maker(
        "Hlt1TrackMVA_Restricted",
        make_track_mva_line(
            restricted_hlt1_reconstruction["forward_tracks"],
            restricted_hlt1_reconstruction["long_track_particles"],
            name="Hlt1TrackMVA_Restricted"),
        enableGEC=True))
lines.append(
    line_maker(
        "Hlt1TwoTrackMVA_Restricted",
        make_two_track_mva_line(
            restricted_hlt1_reconstruction["forward_tracks"],
            restricted_hlt1_reconstruction["secondary_vertices"],
            name="Hlt1TwoTrackMVA_Restricted"),
        enableGEC=True))
lines.append(
    line_maker(
        "Hlt1TrackMVA_Non_Restricted",
        make_track_mva_line(
            non_restricted_hlt1_reconstruction["forward_tracks"],
            non_restricted_hlt1_reconstruction["long_track_particles"],
            name="Hlt1TrackMVA_Non_Restricted"),
        enableGEC=True))
lines.append(
    line_maker(
        "Hlt1TwoTrackMVA_Non_Restricted",
        make_two_track_mva_line(
            non_restricted_hlt1_reconstruction["forward_tracks"],
            non_restricted_hlt1_reconstruction["secondary_vertices"],
            name="Hlt1TwoTrackMVA_Non_Restricted"),
        enableGEC=True))

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
            velo_validation(restricted_hlt1_reconstruction["velo_tracks"])),
        make_composite_node_with_gec(
            "restricted_veloUT_validator",
            veloUT_validation(restricted_hlt1_reconstruction["ut_tracks"],
                              "restricted_veloUT_validator")),
        make_composite_node_with_gec(
            "non-restricted_veloUT_validator",
            veloUT_validation(non_restricted_hlt1_reconstruction["ut_tracks"],
                              "non-restricted_veloUT_validator")),
        make_composite_node_with_gec(
            "restricted_forward_validator",
            forward_validation(
                restricted_hlt1_reconstruction["forward_tracks"],
                "restricted_forward_validator")),
        make_composite_node_with_gec(
            "non-restricted_forward_validator",
            forward_validation(
                non_restricted_hlt1_reconstruction["forward_tracks"],
                "non-restricted_forward_validator")),
        make_composite_node_with_gec(
            "restricted_muon_validation",
            muon_validation(restricted_hlt1_reconstruction["muonID"],
                            "restricted_muon_validation")),
        make_composite_node_with_gec(
            "non-restricted_muon_validation",
            muon_validation(non_restricted_hlt1_reconstruction["muonID"],
                            "non-restricted_muon_validation")),
        make_composite_node_with_gec(
            "pv_validation",
            pv_validation(restricted_hlt1_reconstruction["pvs"])),
        make_composite_node_with_gec(
            "restricted_kalman_validation",
            kalman_validation(
                restricted_hlt1_reconstruction["kalman_velo_only"],
                "restricted_kalman_validation"))
    ],
    NodeLogic.NONLAZY_AND,
    force_order=False)

node = CompositeNode(
    "AllenWithValidators", [hlt1_leaf, validators_leaf],
    NodeLogic.NONLAZY_AND,
    force_order=False)

generate(node)
