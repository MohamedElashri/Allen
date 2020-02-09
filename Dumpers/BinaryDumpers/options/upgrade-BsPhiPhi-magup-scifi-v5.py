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
from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles([
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-0.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-1.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-2.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-3.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-4.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-5.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-6.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-7.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-8.digi',
    'PFN:root://eoslhcb.cern.ch//eos/lhcb/user/g/gligorov/UpgradeStudies/FTv4Sim/Bs2PhiPhi_mu/Boole-Extended-9.digi',
],
                            clear=True)
