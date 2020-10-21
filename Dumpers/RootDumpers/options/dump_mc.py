###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from Configurables import RecSysConf, TrackSys
from Configurables import createODIN, FTRawBankDecoder
from Configurables import NTupleSvc
from Configurables import LHCbApp, CondDB
from Configurables import ProcessPhase, GaudiSequencer
from Configurables import ApplicationMgr
from Configurables import RootHistCnv__PersSvc, HistogramPersistencySvc
from Configurables import RawEventJuggler
from Configurables import PrTrackerDumper, DumpVeloUTState
from Configurables import AuditorSvc, SequencerTimerTool
from Configurables import PrTrackAssociator
from Gaudi.Configuration import appendPostConfigAction

# Upgrade MC
DDDBtag = "dddb-20171010"
CondDBtag = "sim-20170301-vc-md100"

# Brunel is not available, so use LHCbApp
app = LHCbApp(
    DataType="Upgrade",
    EvtMax=50,
    Simulation=True,
    Detectors=["VP", "UT", "FT"],
    DDDBtag=DDDBtag,
    CondDBtag=CondDBtag)

# Brunel is not available, so configure RecSysConf directly
recConf = RecSysConf(
    DataType="Upgrade",
    Simulation=True,
    Detectors=["VP", "UT", "FT"],
    OutputType="None",
    RecoSequence=["Decoding", "TrFast"])

# Configure TrackSys
trackSys = TrackSys(
    TrackingSequence=["Decoding", "TrFast"],
    TrackTypes=["Velo", "Upstream", "Forward"],
    WithMC=True)

# Upgrade DBs
CondDB().Upgrade = True

# Main sequence and sequence for the Juggler to append to
mainSeq = GaudiSequencer("MainSequence")
juggleSeq = GaudiSequencer("JuggleSeq")
juggleSeq.Members = [createODIN()]
mainSeq.Members = [juggleSeq, 'ProcessPhase/Reco']
ApplicationMgr().TopAlg = [mainSeq]

# Correct FT decoding version
FTRawBankDecoder("createFTClusters").DecodingVersion = 2

# Configure histogram output
NTupleSvc().Output = ["FILE1 DATAFILE='velo_states.root' TYP='ROOT' OPT='NEW'"]
ApplicationMgr().HistogramPersistency = "ROOT"
RootHistCnv__PersSvc('RootHistCnv').ForceAlphaIds = True
HistogramPersistencySvc().OutputFile = "dump-histos.root"

# Configure MC linking
linksSeq = ProcessPhase("MCLinks", DetectorList=['Unpack', 'Tr'])
# Unpack Sim data
unpackLinks = GaudiSequencer("MCLinksUnpackSeq")
unpackLinks.Members += ["UnpackMCParticle", "UnpackMCVertex"]
GaudiSequencer("MCLinksTrSeq").Members += ["TrackAssociator"]
mainSeq.Members += ['ProcessPhase/MCLinks']

# Juggle to format 1.0
juggler = RawEventJuggler()
juggler.Input = 4.1
juggler.Output = 1.0
juggler.Sequencer = juggleSeq

# Dump stuff
dumpSeq = GaudiSequencer("DumpSeq")
dump_mc = PrTrackerDumper("DumpMCInfo", DumpToBinary=True)
upstreamTracks = trackSys.DefaultTrackLocations['Upstream']['Location']
dump_vut = DumpVeloUTState("DumpVUT", UpstreamTrackLocation=upstreamTracks)
dumpSeq.Members += [dump_mc, dump_vut]
mainSeq.Members += [dumpSeq]

# Some extra stuff for timing table
ApplicationMgr().ExtSvc += ['ToolSvc', 'AuditorSvc']
ApplicationMgr().AuditAlgorithms = True
AuditorSvc().Auditors += ['TimingAuditor']
SequencerTimerTool().OutputLevel = 4


def modifySequences():
    '''Get rid of the fitter and add MuonRec to get MuonCoords'''
    from Configurables import VectorOfTracksFitter
    GaudiSequencer("RecoTrFastSeq").Members.remove(
        VectorOfTracksFitter("ForwardFitterAlgFast"))
    GaudiSequencer("ForwardFastFittedExtraChecker").Members.remove(
        PrTrackAssociator("ForwardFastFittedAssociator"))
    from Configurables import MuonRec
    GaudiSequencer("RecoDecodingSeq").Members.append(MuonRec())


appendPostConfigAction(modifySequences)

from GaudiKernel.Configurable import applyConfigurableUsers
from Gaudi.Configuration import allConfigurables
applyConfigurableUsers()
print(allConfigurables['PrVeloUTFast'])
