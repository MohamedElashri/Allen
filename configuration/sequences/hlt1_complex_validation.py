###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import gec
from AllenConf.ut_reconstruction import make_ut_tracks
from AllenConf.persistency import make_gather_selections, make_global_decision
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line
from AllenConf.HLT1 import line_maker
from AllenConf.validators import (
    velo_validation, veloUT_validation, forward_validation, muon_validation,
    pv_validation, rate_validation, kalman_validation)

from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate

# Reconstructed objects
with make_ut_tracks.bind(restricted=False):
    non_restricted_hlt1_reconstruction = hlt1_reconstruction()

restricted_hlt1_reconstruction = hlt1_reconstruction()

lines = []
lines.append(
    line_maker(
        "Hlt1TrackMVA_Restricted",
        make_track_mva_line(restricted_hlt1_reconstruction["forward_tracks"],
                            restricted_hlt1_reconstruction["kalman_velo_only"],
                            name="Hlt1TrackMVA_Restricted"),
        enableGEC=True))  
lines.append(
    line_maker(
        "Hlt1TwoTrackMVA_Restricted",
        make_two_track_mva_line(restricted_hlt1_reconstruction["forward_tracks"],
                                restricted_hlt1_reconstruction["secondary_vertices"],
                                name="Hlt1TwoTrackMVA_Restricted"),
        enableGEC=True))
lines.append(
    line_maker(
        "Hlt1TrackMVA_Non_Restricted",
        make_track_mva_line(
            non_restricted_hlt1_reconstruction["forward_tracks"],
            non_restricted_hlt1_reconstruction["secondary_vertices"],
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
    "Allen", [lines_leaf, make_global_decision(lines=line_algorithms)],
    NodeLogic.NONLAZY_AND,
    force_order=True)

validators_leaf = CompositeNode(
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
            make_gather_selections(line_algorithms)),
        kalman_validation(
            restricted_hlt1_reconstruction["kalman_velo_only"],
            name="restricted_kalman_validation")
    ],
    NodeLogic.NONLAZY_AND,
    force_order=False)

node = CompositeNode(
    "AllenWithValidators", [hlt1_leaf, validators_leaf],
    NodeLogic.NONLAZY_AND,
    force_order=False)

generate(node)
