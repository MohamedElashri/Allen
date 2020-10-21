###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from Configurables import LHCbApp, CondDB
from Configurables import GaudiSequencer
from Configurables import FTRawBankDecoder
from Configurables import (PrStoreUTHit, PrStoreFTHit)
from Configurables import ApplicationMgr
from Configurables import HistogramPersistencySvc
from Configurables import (AuditorSvc, SequencerTimerTool)
from Configurables import (DumpUTGeometry, DumpFTGeometry, DumpMuonTable,
                           DumpUTLookupTables, DumpMuonGeometry,
                           DumpVPGeometry)
from Configurables import RootHistCnv__PersSvc
from Configurables import IODataManager
from Configurables import (VPClus, createODIN, TransposeRawBanks, DumpRawBanks,
                           DumpFTHits, DumpMuonCoords, DumpMuonCommonHits,
                           DumpMagneticField, DumpBeamline, MuonRec,
                           PrepareMuonHits, DumpUTHits)
from Configurables import TestMuonTable

app = LHCbApp(
    DataType="Upgrade",
    EvtMax=50,
    Simulation=True,
    DDDBtag="dddb-20171122",
    CondDBtag="sim-20180530-vc-md100")

# Upgrade DBs
CondDB().Upgrade = True

# Decode VP, UT, FT and muons
vp_decoder = VPClus("VPClustering")
store_ut = PrStoreUTHit()
ft_decoder = FTRawBankDecoder("createFTClusters", DecodingVersion=5)
store_ft = PrStoreFTHit()
decode_muon = MuonRec()
muon_hits = PrepareMuonHits()

dec_seq = GaudiSequencer("DecodingSeq")
dec_seq.Members = [
    createODIN(), vp_decoder, store_ut, ft_decoder, store_ft, decode_muon,
    muon_hits
]

# Add the service that will dump the UT and FT geometry
ApplicationMgr().ExtSvc += [
    DumpMagneticField(),
    DumpBeamline(),
    DumpVPGeometry(),
    DumpUTGeometry(),
    DumpFTGeometry(),
    DumpMuonGeometry(),
    DumpMuonTable(),
    DumpUTLookupTables()
]

# Dump raw banks and UT, FT and muon hits
transpose_banks = TransposeRawBanks(
    BankTypes=["VP", "UT", "FTCluster", "Muon", "ODIN"])
dump_banks = DumpRawBanks()
dump_ut = DumpUTHits()
dump_ft = DumpFTHits()
dump_muon_coords = DumpMuonCoords()
dump_muon_hits = DumpMuonCommonHits()
dump_seq = GaudiSequencer("DumpSeq")

dump_seq.Members += [
    transpose_banks, dump_banks, dump_ut, dump_ft, dump_muon_coords,
    dump_muon_hits,
    TestMuonTable()
]

ApplicationMgr().TopAlg = [dec_seq, dump_seq]

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
