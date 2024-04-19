###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node, default_SMOG2_lines
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType
from AllenConf.utils import make_checkPV
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.velo_reconstruction import decode_velo

with decode_velo.bind(retina_decoding=False):
    with make_pvs.bind(zmin=-845., SMOG2_pp_separation=-300., Nbins=4608):
        with make_checkPV.bind(min_z=-717., max_z=-300.):
            with default_SMOG2_lines.bind(min_z=-717., max_z=-300.):
                with make_SMOG2_minimum_bias_line.bind(
                        min_z=-717., max_z=-300.):
                    hlt1_node = setup_hlt1_node(
                        tracking_type=TrackingType.FORWARD_THEN_MATCHING,
                        with_ut=False,
                        withSMOG2=True)

                    generate(hlt1_node)
