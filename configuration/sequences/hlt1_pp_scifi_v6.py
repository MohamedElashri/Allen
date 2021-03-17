###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.HLT1 import setup_hlt1_node
from definitions.scifi_reconstruction import decode_scifi
from AllenConf.event_list_utils import generate

with decode_scifi.bind(raw_bank_version="v6"):
    hlt1_node = setup_hlt1_node()
generate(hlt1_node)
