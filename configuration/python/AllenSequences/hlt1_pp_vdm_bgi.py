###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1_VdMBGI import setup_hlt1_node
from AllenCore.generator import generate

hlt1_node = setup_hlt1_node()
generate(hlt1_node)
