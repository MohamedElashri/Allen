###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.event_list_utils import generate
from AllenConf.scifi_reconstruction import decode_scifi

with decode_scifi.bind(raw_bank_version="v6"),\
     decode_velo.bind(retina_decoding="True"):
    hlt1_node = setup_hlt1_node()
generate(hlt1_node)
