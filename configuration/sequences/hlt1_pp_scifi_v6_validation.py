###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenConf.scifi_reconstruction import decode_scifi
from AllenCore.generator import generate

with decode_scifi.bind(raw_bank_version="v6"):
    hlt1_node = setup_hlt1_node(withMCChecking=True)
generate(hlt1_node)
