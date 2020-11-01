###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
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
