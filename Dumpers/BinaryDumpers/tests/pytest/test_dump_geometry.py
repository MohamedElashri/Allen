###############################################################################
# (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from LHCbTesting import LHCbExeTest
from AllenTesting.preprocessors import preprocessor as AllenPreprocessor
from LHCbTesting.preprocessors import ignore_missing_hepmc_dicts


class Test(LHCbExeTest):
    command = [
        'gaudirun.py', '../../options/sim10aU1_input.py',
        '../../options/dump_geometry.py'
    ]
    reference = '../refs/dump_geometry.yaml'
    timeout = 600

    preprocessor = AllenPreprocessor + ignore_missing_hepmc_dicts
