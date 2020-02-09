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
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-0.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-10.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-11.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-12.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-13.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-14.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-15.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-16.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-17.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-18.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-19.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-1.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-20.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-21.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-22.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-23.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-24.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-25.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-26.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-27.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-28.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-29.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-30.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-31.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-32.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-33.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-35.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-36.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-37.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-38.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-39.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-3.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-40.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-41.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-42.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-43.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-44.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-45.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-46.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-47.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-48.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-49.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-4.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-50.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-51.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-52.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-53.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-54.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-55.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-56.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-57.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-58.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-59.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-5.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-60.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-61.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-62.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-63.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-64.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-65.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-66.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-67.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-68.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-69.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-6.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-70.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-71.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-72.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-73.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-74.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-75.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-76.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-77.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-78.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-79.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-7.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-80.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-81.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-82.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-83.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-84.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-85.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-86.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-87.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-88.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-89.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-8.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-90.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-91.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-92.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-93.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-94.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-95.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-96.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-97.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-98.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-99.digi',
    '/afs/cern.ch/work/d/dovombru/public/MC/upgrade_JPsiMuMu/Boole-6x2-WithSpillover-24142000-50000-9.digi',
],
                            clear=True)
