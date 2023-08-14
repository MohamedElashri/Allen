###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.ut_reconstruction import decode_ut
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decode_ut = CompositeNode("DecodeUT", [decode_ut()["dev_ut_hits"].producer])

generate(decode_ut)
