###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.generator import generate
from AllenConf.scifi_reconstruction import decode_scifi

with decode_velo.bind(retina_decoding=False):
    hlt1_node = setup_hlt1_node(
        enableRateValidator=True,
        matching=True,
        with_muon=False,
        with_ut=False)
generate(hlt1_node)
