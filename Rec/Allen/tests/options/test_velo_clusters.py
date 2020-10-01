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

from Gaudi.Configuration import (HistogramPersistencySvc, ApplicationMgr, EventSelector)
from Configurables import Gaudi__Hive__FetchDataFromFile as FetchDataFromFile
from Configurables import SequencerTimerTool
from Configurables import CondDB, LHCbApp, GaudiSequencer
from Configurables import RootHistCnv__PersSvc
from Configurables import TransposeRawBanks, createODIN, RunAllen
from Configurables import AllenUpdater, TestVeloClusters
from Configurables import (DumpVPGeometry, DumpUTGeometry, DumpFTGeometry,
                           DumpMuonGeometry, DumpMuonTable, DumpMagneticField,
                           DumpBeamline, DumpUTLookupTables)
from GaudiConf import IOHelper

# ROOT persistency
ApplicationMgr().HistogramPersistency = "ROOT"
RootHistCnv__PersSvc('RootHistCnv').ForceAlphaIds = True
HistogramPersistencySvc().OutputFile = "histos.root"

# Event numbers
nEvents = 1000
EventSelector().PrintFreq = 100

# Just to initialise
CondDB(Upgrade=True)
LHCbApp(
    EvtMax=10,
    Simulation=True,
    DDDBtag="dddb-20180815",
    CondDBtag="sim-20180530-vc-md100")

SequencerTimerTool("ToolSvc.SequencerTimerTool").NameSize = 40

all = GaudiSequencer("All", MeasureTime=True)

# Finally set up the application
ApplicationMgr(
    TopAlg=[all],
    EvtMax=nEvents,  # events to be processed
    ExtSvc=['ToolSvc', 'AuditorSvc'],
    AuditAlgorithms=True)

# Setup non-event data for Allen
producers = [
    p(DumpToFile=False)
    for p in (DumpVPGeometry, DumpUTGeometry, DumpFTGeometry,
              DumpMuonGeometry, DumpMuonTable, DumpMagneticField,
              DumpBeamline, DumpUTLookupTables)
]
ApplicationMgr().ExtSvc += [
    AllenUpdater(OutputLevel=2),
] + producers

# ODIN and banks for Allen
odin = createODIN()
allen_banks = TransposeRawBanks()
all.Members += [odin, allen_banks]

allen = RunAllen(
    OutputLevel=2,
    AllenRawInput=allen_banks.AllenRawInput,
    ODINLocation=odin.ODIN,
    ParamDir="${ALLEN_PROJECT_ROOT}/input/detector_configuration/down/",
    FilterGEC=True)

all.Members += [allen]

test_velo_clusters = TestVeloClusters(AllenOutput=allen.AllenOutput)

all.Members += [test_velo_clusters]

data = ["DATAFILE='mdf:root://eoslhcb.cern.ch///eos/lhcb/user/r/raaij/data/upgrade_minbias_scifi_v5/upgrade_mc_minbias_scifi_v5_{:03d}.mdf'".format(i) for i in range(1,7)]
IOHelper('MDF').inputFiles(data, clear=True)
