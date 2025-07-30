###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import os

__path__ += [
    d for d in [
        os.path.realpath(
            os.path.join(
                os.path.dirname(__file__),
                "..",
                "..",
                "code_generation",
                "sequences",
                "AllenAlgorithms",
            ))
    ] if os.path.exists(d)
]
