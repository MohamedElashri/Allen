###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
# DDDBtag = "dddb-20171010"
# CondDBtag = "sim-20180530-vc-md100"

from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles(
    [
        # SciFi v5, minbias
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_1.digi.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_2.digi.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_3.digi.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_4.digi.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_5.digi.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/00067189_6.digi.digi'
    ],
    clear=True)
