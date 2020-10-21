###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from GaudiConf import IOHelper
IOHelper('ROOT').inputFiles(
    [
        # SciFi v4, Ds2KKPi
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p0-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p1-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p2-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p3-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p4-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p5-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p6-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p7-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p8-Extended.digi',
        'PFN:root://eoslhcb.cern.ch//eos/lhcb/wg/SciFi/TestFiles_v64/Ds2KKPi/23263020-FTv64-md-p9-Extended.digi'
    ],
    clear=True)
