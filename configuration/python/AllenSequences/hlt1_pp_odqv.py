###############################################################################
# (c) Copyright 2023-2024 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

# This is the sequence for the Offline Data Quality Validator (ODQV)
# For instructions as to its use see:
# https://gitlab.cern.ch/lhcb-rta/piquet-guide/-/wikis/home/#offline-monitoring

from AllenConf.HLT1 import setup_hlt1_node
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType

hlt1_node = setup_hlt1_node(
    EnableGEC=False,
    data_quality=True,
    with_ut=False,
    # tracking_type is set to matching, but will output both matching and forward
    tracking_type=TrackingType.MATCHING,
    with_lumi=False,
    enableBGI=False,
    withSMOG2=False,
    enablePhysics=True,
    with_calo=True)
generate(hlt1_node)
