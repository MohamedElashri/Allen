###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Write an HLT1-filtered MDF file."""
from PyConf.application import ApplicationOptions
from DDDB.CheckDD4Hep import UseDD4Hep
from PRConfig.TestFileDB import test_file_db

options = ApplicationOptions(_enabled=False)
options.set_input_and_conds_from_testfiledb(
    "upgrade_Sept2022_minbias_0fb_md_mdf")
