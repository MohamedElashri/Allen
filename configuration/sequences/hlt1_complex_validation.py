###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.utils import gec
from definitions.ut_reconstruction import make_ut_tracks
from definitions.persistency import make_gather_selections, make_dec_reporter
from definitions.hlt1_reconstruction import hlt1_reconstruction
from definitions.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line
from definitions.HLT1 import make_line_composite_node_with_gec
from definitions.validators import (
    velo_validation, veloUT_validation, forward_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation)

from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.event_list_utils import generate

# Reconstructed objects
with make_ut_tracks.bind(restricted=False):
    non_restricted_hlt1_reconstruction = hlt1_reconstruction()

restricted_hlt1_reconstruction = hlt1_reconstruction()

# Line definitions
line_algorithms = {
    "Hlt1TrackMVA_Restricted":
    make_track_mva_line(
        restricted_hlt1_reconstruction["forward_tracks"],
        restricted_hlt1_reconstruction["secondary_vertices"],
        name="Hlt1TrackMVA_Restricted"),
    "Hlt1TwoTrackMVA_Restricted":
    make_two_track_mva_line(
        restricted_hlt1_reconstruction["forward_tracks"],
        restricted_hlt1_reconstruction["secondary_vertices"],
        name="Hlt1TwoTrackMVA_Restricted"),
    "Hlt1TrackMVA_Non_Restricted":
    make_track_mva_line(
        non_restricted_hlt1_reconstruction["forward_tracks"],
        non_restricted_hlt1_reconstruction["secondary_vertices"],
        name="Hlt1TrackMVA_Non_Restricted"),
    "Hlt1TwoTrackMVA_Non_Restricted":
    make_two_track_mva_line(
        non_restricted_hlt1_reconstruction["forward_tracks"],
        non_restricted_hlt1_reconstruction["secondary_vertices"],
        name="Hlt1TwoTrackMVA_Non_Restricted"),
}

track_mva_line_restricted = make_line_composite_node_with_gec(
    "Hlt1TrackMVA_Restricted", line_algorithms)
two_track_mva_line_restricted = make_line_composite_node_with_gec(
    "Hlt1TwoTrackMVA_Restricted", line_algorithms)
track_mva_line_non_restricted = make_line_composite_node_with_gec(
    "Hlt1TrackMVA_Non_Restricted", line_algorithms)
two_track_mva_line_non_restricted = make_line_composite_node_with_gec(
    "Hlt1TwoTrackMVA_Non_Restricted", line_algorithms)

lines_leaf = CompositeNode(
    "AllLines", [
        track_mva_line_restricted, two_track_mva_line_restricted,
        track_mva_line_non_restricted, two_track_mva_line_non_restricted
    ],
    NodeLogic.NONLAZY_OR,
    forceOrder=False)

hlt1_node = CompositeNode(
    "Allen", [
        lines_leaf,
        make_dec_reporter(lines=line_algorithms.values()),
    ],
    NodeLogic.NONLAZY_AND,
    forceOrder=True)

validators_node = CompositeNode(
    "Validators", [
        velo_validation(restricted_hlt1_reconstruction["velo_tracks"]),
        veloUT_validation(
            restricted_hlt1_reconstruction["ut_tracks"],
            name="restricted_veloUT_validator"),
        veloUT_validation(
            non_restricted_hlt1_reconstruction["ut_tracks"],
            name="non-restricted_veloUT_validator"),
        forward_validation(
            restricted_hlt1_reconstruction["forward_tracks"],
            name="restricted_forward_validator"),
        forward_validation(
            non_restricted_hlt1_reconstruction["forward_tracks"],
            name="non-restricted_forward_validator"),
        muon_validation(
            restricted_hlt1_reconstruction["muonID"],
            name="restricted_muon_validation"),
        muon_validation(
            non_restricted_hlt1_reconstruction["muonID"],
            name="non-restricted_muon_validation"),
        pv_validation(restricted_hlt1_reconstruction["pvs"]),
        rate_validation(
            make_gather_selections(lines=line_algorithms.values())),
        kalman_validation(
            restricted_hlt1_reconstruction["kalman_velo_only"],
            name="restricted_kalman_validation")
    ],
    NodeLogic.NONLAZY_AND,
    forceOrder=False)

node = CompositeNode(
    "AllenWithValidators", [hlt1_node, validators_node],
    NodeLogic.NONLAZY_AND,
    forceOrder=False)

generate(node)

# # Generate a pydot graph out of the configuration
# from pydot import Graph
# y = Graph()
# hlt1_node._graph(y)
# with open('blub.dot', 'w') as f:
#     f.write(y.to_string())
