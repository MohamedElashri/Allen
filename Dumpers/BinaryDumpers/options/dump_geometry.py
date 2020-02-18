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
from GaudiPython.Bindings import AppMgr
from Configurables import LHCbApp, CondDB
from Configurables import GaudiSequencer
from Configurables import FTRawBankDecoder
from Configurables import (PrStoreUTHit, PrStoreFTHit)
from Configurables import ApplicationMgr
from Configurables import HistogramPersistencySvc
from Configurables import (AuditorSvc, SequencerTimerTool)
from Configurables import (DumpUTGeometry, DumpFTGeometry, DumpMuonTable,
                           DumpUTLookupTables, DumpMuonGeometry,
                           DumpCaloGeometry, DumpVPGeometry,
                           DumpMagneticField, DumpBeamline)
from Configurables import RootHistCnv__PersSvc
from Configurables import IODataManager
from Configurables import createODIN
from Configurables import TestMuonTable

app = LHCbApp(
    DataType="Upgrade",
    EvtMax=50,
    Simulation=True,
    DDDBtag="dddb-20171122",
    CondDBtag="sim-20180530-vc-md100")

# Upgrade DBs
CondDB().Upgrade = True

dec_seq = GaudiSequencer("DecodingSeq")
dec_seq.Members = [
    createODIN()
]

ecal_location = "/dd/Structure/LHCb/DownstreamRegion/Ecal"
hcal_location = "/dd/Structure/LHCb/DownstreamRegion/Hcal"

ecal_geom = DumpCaloGeometry("DumpEcal", Location=ecal_location)
hcal_geom = DumpCaloGeometry("DumpHcal", Location=hcal_location)

# Add the service that will dump the UT and FT geometry
ApplicationMgr().ExtSvc += [
    DumpMagneticField(),
    DumpBeamline(),
    DumpVPGeometry(),
    DumpUTGeometry(),
    DumpFTGeometry(),
    DumpMuonGeometry(),
    DumpMuonTable(),
    DumpUTLookupTables(),
    ecal_geom,
    hcal_geom
]

ApplicationMgr().TopAlg = [dec_seq]

# Some extra stuff for timing table
ApplicationMgr().ExtSvc += ['ToolSvc', 'AuditorSvc']
ApplicationMgr().AuditAlgorithms = True
AuditorSvc().Auditors += ['TimingAuditor']
SequencerTimerTool().OutputLevel = 4

# Some extra stuff to save histograms
ApplicationMgr().HistogramPersistency = "ROOT"
RootHistCnv__PersSvc('RootHistCnv').ForceAlphaIds = True
HistogramPersistencySvc().OutputFile = "dump-histos.root"

# No error messages when reading MDF
IODataManager().DisablePFNWarning = True

# GaudiPython
gaudi = AppMgr()
gaudi.initialize()
detSvc = gaudi.detSvc()
ecal = detSvc[ecal_location]
hcal = detSvc[hcal_location]
