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
from AllenConf.filters import make_gec
from AllenConf.enum_types import TrackingType
from AllenConf.persistency import make_routingbits_writer, rb_map_PbPb
from AllenConf.calo_reconstruction import make_ecal_clusters

with make_gec.bind(max_scifi_clusters=30000, count_ut=False):
    with make_routingbits_writer.bind(rb_map=rb_map_PbPb):
        with make_ecal_clusters.bind(
                seed_min_adc=10, neighbour_min_adc=2, min_et=200, min_e19=0):
            hlt1_node = setup_hlt1_node(
                with_ut=False,
                EnableGEC=True,
                max_ecal_upc=800000,
                min_ecal_hadro=94000,
                tracking_type=TrackingType.FORWARD_THEN_MATCHING,
                bx_type=[1, 3],
                mini=True)
            generate(hlt1_node)
