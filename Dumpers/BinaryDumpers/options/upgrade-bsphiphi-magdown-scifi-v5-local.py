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
# DDDBtag = "dddb-20171010"
# CondDBtag = "sim-20180530-vc-md100"

from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles(
    [
        # SciFi v5, bsphiphi
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/RawBanksv5/Boole_0_evt1k_13104012_MagDown_v5_new.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/RawBanksv5/Boole_1_evt1k_13104012_MagDown_v5_new.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/RawBanksv5/Boole_2_evt1k_13104012_MagDown_v5_new.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/RawBanksv5/Boole_3_evt1k_13104012_MagDown_v5_new.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/RawBanksv5/Boole_4_evt1k_13104012_MagDown_v5_new.digi'
    ],
    clear=True)
