###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from GaudiTesting.BaseTest import LineSkipper
from GaudiConf.QMTest.LHCbTest import BlockSkipper
from GaudiConf.QMTest.LHCbExclusions import preprocessor as LHCbPreprocessor

remove_throughput = LineSkipper(regexps=[
    # Throughput messages
    r"\s*(\d+\.\d+)\s+events/s",
    r"Ran test for (\d+\.\d+)\s+seconds",
    r"Providing events in.*",
    r"Opened\s.*",
    r"Cannot read more data.*"
])

skip_options = BlockSkipper("Requested options:",
                            "Setting number of slices to 2")

preprocessor = LHCbPreprocessor + remove_throughput + skip_options
