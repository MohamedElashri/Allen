###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles(
    [
        # SciFi v4, Ds2KKPi
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p0-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p1-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p2-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p3-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p4-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p5-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p6-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p7-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p8-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-mu-p9-Extended.digi'
    ],
    clear=True)
