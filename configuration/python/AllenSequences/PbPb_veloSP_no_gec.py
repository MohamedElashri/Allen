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
from AllenConf.velo_reconstruction import velo_tracking, decode_velo
from AllenConf.calo_reconstruction import ecal_cluster_reco
from AllenConf.primary_vertex_reconstruction import pv_finder
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    node = CompositeNode(
        "PbPbRecoNoGEC", [pv_finder(), ecal_cluster_reco()],
        NodeLogic.NONLAZY_OR,
        force_order=True)

generate(node)
