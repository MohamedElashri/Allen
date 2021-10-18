###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1_ECAL import setup_hlt1_node
from AllenCore.generator import generate

hlt1_ecal_node = setup_hlt1_node()
generate(hlt1_ecal_node)
