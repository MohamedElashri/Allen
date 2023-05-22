###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Write an HLT1-filtered MDF file."""
from PyConf.application import ApplicationOptions
from DDDB.CheckDD4Hep import UseDD4Hep

options = ApplicationOptions(_enabled=False)

options.input_files = [
    "mdf:root://eoslhcb.cern.ch//eos/lhcb/hlt2/LHCb/0000248711/Run_0000248711_HLT20840_20221011-113809-426.mdf"
]
options.input_type = 'MDF'
options.conddb_tag = "upgrade/master"
options.dddb_tag = "upgrade/master"
options.conditions_version = "alignment2022"
options.geometry_version = "trunk"
options.simulation = not UseDD4Hep
