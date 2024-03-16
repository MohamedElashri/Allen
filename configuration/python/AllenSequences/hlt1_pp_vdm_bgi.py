###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.HLT1 import setup_hlt1_node, default_bgi_activity_lines
from AllenCore.generator import generate

with default_bgi_activity_lines.bind(enableBGI_full=True):
    hlt1_node = setup_hlt1_node(
        enablePhysics=False,
        withSMOG2=True,
        enableBGI=True,
        with_ut=False,
    )
generate(hlt1_node)
