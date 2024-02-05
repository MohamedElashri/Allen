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
from AllenConf.muon_reconstruction import muon_id
from AllenCore.generator import generate
from PyConf.control_flow import NodeLogic, CompositeNode

muon_id_sequence = CompositeNode(
    "MuonID", [muon_id(algorithm_name='muon_id_sequence')],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(muon_id_sequence)
