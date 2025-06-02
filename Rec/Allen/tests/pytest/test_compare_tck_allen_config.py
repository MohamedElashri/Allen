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
import glob
import pytest
from LHCbTesting import LHCbExeTest


@pytest.mark.ctest_fixture_required('allen.create_tcks')
@pytest.mark.shared_cwd('Allen')
class Test(LHCbExeTest):
    command = ['python', '../options/test_tck_allen_write_config.py']
    timeout = 1800
