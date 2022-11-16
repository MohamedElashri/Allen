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
    # Processing complete messages
    r"Processing complete",
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

skip_options = BlockSkipper("Requested options:",
                            "Configure the device to use more shared")

skip_rates = BlockSkipper("rate_validator validation:", "Inclusive:")

skip_lbdd4hep = LineSkipper(regexps=[
    r"LHCb::Det::LbDD4hep::DD4hepSvc.*", r"ReserveIOVDD4hep.*", r"XmlCnvSvc.*",
    r"DeMagnetConditionCall.*", r"MagneticFieldExtension", r"TGeoMixture.*"
])

skip_detdesc = LineSkipper(regexps=[
    r".*Current FT geometry version.*",
    r".*Removing all tools created by ToolSvc.*",
    r".*Detector description database:.*"
])

skip_sequence = BlockSkipper("Sequence:", "make_lumi_summary") + BlockSkipper(
    "prefix_sum_max_objects", "make_selreps")

preprocessor_with_rates = (
    LHCbPreprocessor + skip_config + skip_options + skip_sequence +
    skip_lbdd4hep + skip_detdesc + remove_throughput)

preprocessor = preprocessor_with_rates + skip_rates
