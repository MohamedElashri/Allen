###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.HLT1 import setup_hlt1_node, default_hlt1_lines
from AllenConf.event_list_utils import generate

with default_hlt1_lines.bind(withGECPassthrough=False):
    hlt1_node = setup_hlt1_node(EnableGEC=False)
generate(hlt1_node)
