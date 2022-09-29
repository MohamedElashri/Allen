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
class AllenConfigurationOptions:
    def __init__(self):
        from optparse import OptionParser
        parser = OptionParser()
        parser.add_option("--standalone", dest="standalone", default="0")
        parser.add_option("--register-keys", dest="register_keys", default="1")
        (options, _) = parser.parse_args()
        self.standalone = options.standalone == "1"
        self.register_keys = options.register_keys == "1"


allen_configuration_options = AllenConfigurationOptions()
