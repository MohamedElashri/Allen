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


class Test(LHCbExeTest):
    command = [
        'python', '../../../../Dumpers/BinaryDumpers/options/allen.py',
        '--test-file-db-key', '2023_raw_hlt1_269138', '--monitoring-filename',
        'mdf_data_hists.root', '--sequence',
        '${ALLEN_INSTALL_DIR}/constants//hlt1_pp_forward_then_matching_no_ut.json',
        '--real-data'
    ]
    timeout = 60000

    reference = {"messages_count": {"FATAL": 0, "ERROR": 0, "WARNING": 0}}
