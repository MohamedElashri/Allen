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

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.filters import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)

kalman_filter = velo_states['dev_velo_kalman_endvelo_states'].producer

node = CompositeNode(
    "VeloTracking", [kalman_filter], NodeLogic.LAZY_AND, force_order=True)

# This is for import by the allen_gaudi_velo_with_mcchecking test
config = {
    'control_flow_node': node,
    'reconstruction': {
        'velo_tracks': velo_tracks,
        'velo_states': velo_states
    }
}

generate(node)
