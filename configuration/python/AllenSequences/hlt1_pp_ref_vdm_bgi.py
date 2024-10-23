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
from AllenConf.HLT1_pp_ref import setup_hlt1_node
from AllenConf.enum_types import TrackingType
from AllenConf.get_thresholds import get_thresholds
from AllenCore.generator import generate
from AllenConf.HLT1_pp_ref import default_bgi_activity_lines

default_bgi_activity_lines.global_bind(enableBGI_full=True)

hlt1_node = setup_hlt1_node(
    tracking_type=TrackingType.FORWARD_THEN_MATCHING,
    threshold_settings=get_thresholds("pp_reference_run_2024"))

generate(hlt1_node)
