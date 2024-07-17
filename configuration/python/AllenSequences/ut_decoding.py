###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.ut_reconstruction import decode_ut
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

decode_ut = CompositeNode("DecodeUT", [decode_ut()["dev_ut_hits"].producer])

generate(decode_ut)
