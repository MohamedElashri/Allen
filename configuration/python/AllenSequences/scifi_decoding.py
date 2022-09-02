###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.scifi_reconstruction import decode_scifi
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decode_scifi = CompositeNode("DecodeScifi",
                             [decode_scifi()["dev_scifi_hits"].producer])

generate(decode_scifi)
