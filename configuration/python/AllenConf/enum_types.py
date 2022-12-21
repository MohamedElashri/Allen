###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from enum import Enum


class TrackingType(Enum):
    FORWARD = 0
    MATCHING = 1
    FORWARD_THEN_MATCHING = 2
    MATCHING_THEN_FORWARD = 3


def includes_matching(tracking_type):
    return tracking_type in (TrackingType.MATCHING,
                             TrackingType.FORWARD_THEN_MATCHING,
                             TrackingType.MATCHING_THEN_FORWARD)
