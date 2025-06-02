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
import pytest
from pathlib import Path
from LHCbTesting import LHCbExeTest
from GaudiTesting.preprocessors import LineSkipper


@pytest.mark.ctest_fixture_required('binarydumpers.lhcb_odqv')
@pytest.mark.shared_cwd('BinaryDumpers')
class Test(LHCbExeTest):
    command = [
        'root', '-l', '-x', '-b', '-q',
        '../../../../scripts/DataQualityPlot_Overlay.cc'
    ]
    timeout = 120
    environment = [f"PYTEST_NAME={__name__}"]

    # Mitigation to issue discussed in LHCb#193
    def test_stderr(self, stderr: bytes):
        stderr_preprocessor = LineSkipper(regexps=[
            r"Info in <TCanvas::Print>: pdf file.*has been created",
            r"WARNING : LHCbStyle file not found, default plotting style will be used ...",
            r"        : For best results put a copy of LHCbStyle.C in the Allen/scripts folder"
        ])
        assert stderr_preprocessor(stderr.decode()) == ""

    def test_expected_files(self, cwd: Path):

        assert os.path.exists(
            cwd / "allen_odqv_pytest.root"
        ), "Couldn't find input file allen_odqv_pytest.root from the prerequisite job!\n"

        expectedFiles = [
            "fileCanvas.pdf", "IPforwardCanvas.pdf", "IPmatchingCanvas.pdf",
            "kalmanCovCanvas.pdf", "longForwardCanvas.pdf",
            "longMatchingCanvas.pdf", "occupancyCanvas.pdf", "PIDCanvas.pdf",
            "PIDkinCanvas.pdf", "PVcanvas.pdf", "PVcovCanvas.pdf",
            "PVdistCanvas.pdf", "IPresolutionCanvas.pdf", "veloCanvas.pdf"
        ]

        for file in expectedFiles:
            assert os.path.exists(
                cwd / file), f"could not find expected output file: {file} \n"
