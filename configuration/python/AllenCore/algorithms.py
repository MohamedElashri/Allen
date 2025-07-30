###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.configuration_options import is_allen_standalone

from sys import modules
if is_allen_standalone():
    from AllenAlgorithms import allen_standalone_algorithms
    modules[__name__] = allen_standalone_algorithms
else:
    from PyConf.importers import AlgorithmImporter
    modules[__name__] = AlgorithmImporter(__file__, __name__)
