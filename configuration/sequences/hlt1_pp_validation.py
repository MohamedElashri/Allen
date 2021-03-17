###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

from definitions.HLT1 import setup_hlt1_node
from AllenConf.event_list_utils import generate

hlt1_node = setup_hlt1_node(withMCChecking=True)
generate(hlt1_node)
