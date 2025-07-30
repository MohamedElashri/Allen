###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenConf.thresholds.thresholds import Thresholds


def get_thresholds(threshold_setting_name):
    try:
        try:
            threshold_module = __import__(
                f"AllenConf.thresholds.{threshold_setting_name}",
                fromlist=[None])
        except:
            print("Failed to load module")
        settings = getattr(threshold_module, "threshold_settings")
        return settings
    except:
        print(
            f"Error: {threshold_setting_name} not a valid set of threshold settings"
        )
