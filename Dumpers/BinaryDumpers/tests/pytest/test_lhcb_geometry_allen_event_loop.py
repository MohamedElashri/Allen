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
import re
from LHCbTesting import LHCbExeTest


class Test(LHCbExeTest):
    command = [
        'python', '../../options/allen.py', '--test-file-db-key',
        'upgrade_Sept2022_minbias_0fb_md_mdf', '--sequence',
        '$ALLEN_INSTALL_DIR/constants/hlt1_pp_no_ut.json',
        '--monitoring-filename', 'allen_event_loop.root', '-n', '10000'
    ]
    timeout = 600

    reference = {"messages_count": {"FATAL": 0, "ERROR": 0, "WARNING": 0}}

    def test_throughput_output(self, stdout: bytes):

        throughput_pattern = re.compile(r'\s*(\d+\.\d+)\s+events/s')
        time_pattern = re.compile(r'Ran test for (\d+\.\d+)\s+seconds')

        throughput = None
        runtime = None

        for line in stdout.decode().split('\n'):
            m = throughput_pattern.match(line)
            if m:
                throughput = float(m.group(1))
            n = time_pattern.match(line)
            if n:
                runtime = float(n.group(1))

        assert throughput is not None, 'could not parse throughput from stdout'
        assert runtime is not None, 'could not parse runtime from stdout'
