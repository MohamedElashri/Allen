###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    hlt1_node = setup_hlt1_node(EnableGEC=False, matching=True)
generate(hlt1_node)
