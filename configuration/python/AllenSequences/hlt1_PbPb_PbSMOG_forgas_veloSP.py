###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
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
from AllenConf.enum_types import TrackingType, ActivityType
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.persistency import make_routingbits_writer, rb_map_PbPb
from AllenConf.hlt1_heavy_ions_lines import make_heavy_ion_event_line
from AllenConf.calo_reconstruction import make_ecal_clusters

with decode_velo.bind(retina_decoding=False):
    with make_routingbits_writer.bind(rb_map=rb_map_PbPb):
        with make_ecal_clusters.bind(
                seed_min_adc=10, neighbour_min_adc=2, min_et=200, min_e19=0):
            with make_heavy_ion_event_line.bind(PbPb_SMOG_z_separation=-330.):
                hlt1_node = setup_hlt1_node(
                    prescale=True,
                    with_ut=True,
                    EnableGEC=True,
                    reco_particles=True,
                    tracking_type=TrackingType.FORWARD_THEN_MATCHING,
                    ActivityForClosing=ActivityType.PRIMARY_VERTICES)
                generate(hlt1_node)
