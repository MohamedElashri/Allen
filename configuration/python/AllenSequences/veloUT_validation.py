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
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.validators import veloUT_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks

decoded_velo = decode_velo(retina_decoding=True)
velo_tracks = make_velo_tracks(decoded_velo)
decoded_ut = decode_ut()
ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)

ut_tracking_sequence = CompositeNode(
    "UTTracking", [veloUT_validation(ut_tracks)],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(ut_tracking_sequence)
