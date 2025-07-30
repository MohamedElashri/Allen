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
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.utils import line_maker, make_invert_event_list
from AllenConf.hlt1_electron_lines import *
from AllenConf.persistency import make_global_decision
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.validators import rate_validation
from AllenCore.generator import generate
from AllenConf.get_thresholds import get_thresholds
from AllenConf.enum_types import TrackingType
reconstructed_objects = hlt1_reconstruction(
    with_muon=True,
    with_calo=True,
    tracking_type=TrackingType.FORWARD_THEN_MATCHING)
thresholds = get_thresholds('default')
long_tracks = reconstructed_objects["long_tracks"]
prompt_dihadrons = reconstructed_objects["prompt_dihadron_secondary_vertices"]
prompt_dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
dileptons = reconstructed_objects["dilepton_secondary_vertices"]
electronid_nn = reconstructed_objects["electronid_nn"]
calo_matching_objects = reconstructed_objects["calo_matching_objects"]
lines = []

for subSample in ["NoIP", "NoIPNorm", "Displaced"]:
    common_kwargs_low_mass_electron = {
        "minMass": 5,
        "maxMass": 300,
        "minPTprompt": 500,
        "minPTdisplaced": 0.0,
        "trackIPChi2Threshold": -1 if "NoIP" in subSample else
        2,  # it will only be picked up by the displaced line the NoIP (aka prompt) won't trigger this cut
        "selectPrompt": "NoIP" in subSample,
        "useNN": True,
        "nnCut": 0.94 if subSample == "NoIP" else 0.75,
        "enable_monitoring": True
    }
    lines.append(
        make_lowmass_dielectron_line(
            long_tracks,
            dileptons,
            electronid_nn,
            calo_matching_objects,
            **common_kwargs_low_mass_electron,
            name="Hlt1DiElectronLowMass_{}".format(subSample),
            pre_scaler_hash_string="Hlt1DiElectronLowMass_massSlice_{}_pre".
            format(subSample),
            post_scaler=0.0 if subSample == "NoIPNorm" else 1,
        ))
    lines.append(
        make_lowmass_dielectron_line(
            long_tracks,
            dileptons,
            electronid_nn,
            calo_matching_objects,
            **common_kwargs_low_mass_electron,
            is_same_sign=True,
            name="Hlt1DiElectronLowMass_SS_{}".format(subSample),
            pre_scaler_hash_string="Hlt1DiElectronLowMass_massSlice_SS_{}_pre".
            format(subSample),
            post_scaler=0.0,
        ))
lines = [line_maker(line) for line in lines]
line_algorithms = [line[0] for line in lines]
line_whatever = [line[1] for line in lines]
global_decision = make_global_decision(lines=line_algorithms)

lines = CompositeNode(
    "AllLines", line_whatever, NodeLogic.NONLAZY_OR, force_order=False)

calo_sequence = CompositeNode(
    "Electron",
    [lines, global_decision,
     rate_validation(lines=line_algorithms)],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(calo_sequence)
