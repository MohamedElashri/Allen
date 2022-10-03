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
from PyConf.tonic import configurable


class AllenConfigurationOptions:
    def __init__(self):
        from argparse import ArgumentParser, BooleanOptionalAction
        parser = ArgumentParser()
        parser.add_argument(
            "--standalone",
            action="store_true",
            dest="standalone",
            default=False)
        parser.add_argument(
            "--no-register-keys",
            action="store_false",
            dest="register_keys",
            default=True)
        args, _ = parser.parse_known_args()
        self.standalone = args.standalone
        self.register_keys = args.register_keys


allen_configuration_options = AllenConfigurationOptions()
