###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.rich_reconstruction import decode_rich
from AllenCore.generator import generate
from PyConf.control_flow import NodeLogic, CompositeNode

rich_decoding = CompositeNode(
    "RichDecoding", [decode_rich()["dev_smart_ids"].producer],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(rich_decoding)
