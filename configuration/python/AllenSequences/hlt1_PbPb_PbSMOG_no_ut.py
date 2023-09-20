###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.HLT1_PbPb import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.utils import make_gec
from AllenConf.enum_types import TrackingType
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.primary_vertex_reconstruction import make_pvs
from AllenConf.persistency import make_routingbits_writer, rb_map_PbPb
from AllenConf.hlt1_heavy_ions_lines import make_heavy_ion_event_line

with make_gec.bind(max_scifi_clusters=30000, count_ut=False):
    with make_pvs.bind(zmin=-845., Nbins=4608, SMOG2_pp_separation=-300.):
        with make_routingbits_writer.bind(rb_map=rb_map_PbPb):
            with make_heavy_ion_event_line.bind(PbPb_SMOG_z_separation=-300.):
                hlt1_node = setup_hlt1_node(
                    with_ut=False,
                    EnableGEC=True,
                    bx_type=[1, 3],
                    tracking_type=TrackingType.FORWARD_THEN_MATCHING)
                generate(hlt1_node)
