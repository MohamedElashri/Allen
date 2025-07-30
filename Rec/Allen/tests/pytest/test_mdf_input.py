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
        '--monitoring-filename', 'mdf_input_hists.root', '--test-file-db-key',
        'upgrade_Sept2022_minbias_0fb_md_mdf', '--sequence',
        '${ALLEN_INSTALL_DIR}/constants/hlt1_pp_matching.json',
        '--events-per-slice', '500', '-m', '600', '-s', '3', '-t', '2', '-n',
        '10000'
    ]
    reference = '../refs/allen_event_loop.yaml'
    timeout = 600

    preprocessor = AllenPreprocessor
