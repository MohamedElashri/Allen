###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
# -- GAUDI jobOptions generated on Mon Oct 30 12:18:44 2017
# -- Contains event types :
# --   30000000 - 77 files - 92213 events - 305.47 GBytes

# --  Extra information about the data processing phases:

# --  Processing Pass Step-132412

# --  StepId : 132412
# --  StepName : Digi14b-Upgrade for Upgrade studies with spillover - 2017 Baseline NoRichSpillover - xdigi
# --  ApplicationName : Boole
# --  ApplicationVersion : v31r3
# --  OptionFiles : $APPCONFIGOPTS/Boole/Default.py;$APPCONFIGOPTS/Boole/Boole-Upgrade-Baseline-20150522.py;$APPCONFIGOPTS/Boole/EnableSpillover.py;$APPCONFIGOPTS/Boole/Upgrade-RichMaPMT-NoSpilloverDigi.py;$APPCONFIGOPTS/Boole/xdigi.py
# --  DDDB : dddb-20171010
# --  CONDDB : sim-20170301-vc-md100
# --  ExtraPackages : AppConfig.v3r338
# --  Visible : N
from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles([
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/grid/prod/lhcb/MC/Upgrade/XDIGI/00067189/0000/00067189_00000013_1.xdigi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/grid/prod/lhcb/MC/Upgrade/XDIGI/00067189/0000/00067189_00000020_1.xdigi'
],
                            clear=True)
