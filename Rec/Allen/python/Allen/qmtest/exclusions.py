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
    r"Providing banks for",
    r"Providing events in.*",
    r"Opened\s.*",
    r"Cannot read more data.*"
])

skip_config = BlockSkipper("User ApplicationOptions",
                           "Application Manager Configured successfully")

skip_options = BlockSkipper("Requested options:", "Ignore signals to update")

skip_rates = BlockSkipper("rate_validator validation:", "Inclusive:")

skip_sequence = BlockSkipper("Sequence:",
                             "Starting timer for throughput measurement")

preprocessor = (LHCbPreprocessor + skip_config + remove_throughput +
                skip_options + skip_rates + skip_sequence)
