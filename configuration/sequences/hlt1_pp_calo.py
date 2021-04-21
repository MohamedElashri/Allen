###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.event_list_utils import generate
from AllenConf.calo_reconstruction import decode_calo
from PyConf.control_flow import NodeLogic, CompositeNode

hlt1_node = setup_hlt1_node()

calo_node = CompositeNode(
    "CaloReconstruction",
    [hlt1_node, decode_calo()["dev_ecal_digits"].producer],
    NodeLogic.NONLAZY_AND,
    force_order=False)

generate(calo_node)
