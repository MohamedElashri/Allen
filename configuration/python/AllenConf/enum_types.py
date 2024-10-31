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
from enum import Enum


class TrackingType(Enum):
    FORWARD = 0
    MATCHING = 1
    FORWARD_THEN_MATCHING = 2
    MATCHING_THEN_FORWARD = 3


class ActivityType(Enum):
    VELO_CLUSTERS = 0
    VELO_TRACKS = 1
    PRIMARY_VERTICES = 2
    SCIFI_CLUSTERS = 3
    LONG_TRACKS = 4


def includes_matching(tracking_type):
    return tracking_type in (TrackingType.MATCHING,
                             TrackingType.FORWARD_THEN_MATCHING,
                             TrackingType.MATCHING_THEN_FORWARD)
