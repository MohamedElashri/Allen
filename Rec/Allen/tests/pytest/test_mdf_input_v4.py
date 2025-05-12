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


class Test(LHCbExeTest):
    command = [
        'python', '../../../../Dumpers/BinaryDumpers/options/allen.py',
        '--monitoring-filename', 'mdf_input_hists_v4.root',
        '--test-file-db-key', 'plume-raw-data-v4', '--sequence',
        '${ALLEN_INSTALL_DIR}/constants/hlt1_pp_matching.json',
        '--events-per-slice', '500', '-m', '600', '-s', '3', '-t', '2', '-n',
        '10000'
    ]
    reference = '../refs/allen_event_loop_v4.yaml'
    timeout = 600

    preprocessor = AllenPreprocessor
