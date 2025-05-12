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
import os
import re
import pytest
from LHCbTesting import LHCbExeTest
from pathlib import Path


@pytest.mark.ctest_fixture_setup('binarydumpers.lhcb_odqv')
@pytest.mark.shared_cwd('BinaryDumpers')
class Test(LHCbExeTest):
    command = [
        'python', '../../options/allen.py', '--sequence',
        '$ALLEN_INSTALL_DIR/constants/hlt1_pp_odqv.json', '--test-file-db-key',
        'upgrade_Sept2022_minbias_0fb_md_mdf', '-n', '10000',
        '--monitoring-filename', 'allen_odqv_pytest.root'
    ]
    timeout = 1200

    def test_expected_files(self, cwd: Path):
        assert os.path.exists(cwd / "allen_odqv_pytest.root"
                              ), "Couldn't find file allen_odqv_pytest.root!\n"

    def test_modules(self, stdout: bytes):

        modules = ["occupancy", "velo", "forward", "matching", "pv"]
        algorithm_patterns = [
            re.compile(rf'^  data_quality_validation_{m}$') for m in modules
        ]
        time_pattern = re.compile(r'Ran test for (\d+\.\d+)\s+seconds')

        time = None
        algorithms = [None for m in modules]

        for line in stdout.decode().split('\n'):
            #Check the modules are all there
            for i, alg in enumerate(algorithm_patterns):
                match = alg.match(line)
                if match is not None: algorithms[i] = match

            #Check the time elapsed is there
            time_pattern_match = time_pattern.match(line)
            if time_pattern_match:
                runtime = float(time_pattern_match.group(1))

        #If the messages did not appear, log that and fail the test
        for i, module in enumerate(modules):
            assert algorithms[
                i] is not None, f'could not find module: {module}  in stdout\n'

        assert runtime is not None, 'could not parse runtime from stdout'
