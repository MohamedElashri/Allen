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
import pytest
from LHCbTesting import LHCbExeTest
from AllenTesting.validators import check_large_event_histograms
from pathlib import Path


@pytest.mark.ctest_fixture_required("allen.large_event_passthrough")
@pytest.mark.shared_cwd("Allen")
class Test(LHCbExeTest):
    command = [
        "gaudirun.py",
        "../options/large_event_output.py",
        "../options/hlt1_decoding.py",
    ]
    reference = {"messages_count": {"FATAL": 0, "ERROR": 0, "WARNING": 0}}

    def test_expected_files(self, cwd: Path):
        print(cwd)
        line_name, pass_counts, rb_counts = check_large_event_histograms(
            str(cwd / "large_event_passthrough.root"))

        assert list(pass_counts.values()) == [
            2
        ], "Pass counts {} are not [2] as expected (line name is: {})".format(
            rb_counts, line_name)
        assert rb_counts == {
            26: 2
        }, "Routing bit counts {} are not [(26, 2)] as expected (line name is: {})".format(
            rb_counts, line_name)
