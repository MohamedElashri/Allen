###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from collections import defaultdict


def pvEfficiencyHistoDict():
    basedict = {
        "z": {},
        "mult": {},
    }

    basedict["z"]["xTitle"] = "z [mm]"
    basedict["z"]["title"] = "z"

    basedict["mult"]["xTitle"] = "track multiplicity of MC PV"
    basedict["mult"]["title"] = "multiplicity"

    return basedict
