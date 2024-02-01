###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.rich_reconstruction import decode_rich
from PyConf.control_flow import NodeLogic, CompositeNode

hlt1_node = setup_hlt1_node(with_ut=False, with_rich=True)
generate(hlt1_node)
