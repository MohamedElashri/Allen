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
from AllenCore.configuration_options import allen_configuration_options

from sys import modules
if allen_configuration_options.standalone:
    from AllenCore import allen_standalone_generator
    modules[__name__] = allen_standalone_generator
else:
    from AllenCore import gaudi_allen_generator
    modules[__name__] = gaudi_allen_generator
