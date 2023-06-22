###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.utils import make_gec
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

kalman_sequence = CompositeNode(
    "KalmanSequence", [
        make_gec("gec"),
        hlt1_reconstruction(algorithm_name='kalman_sequence')
        ["secondary_vertices"]["dev_two_track_particles"].producer
    ],
    NodeLogic.LAZY_AND,
    force_order=True)
generate(kalman_sequence)
