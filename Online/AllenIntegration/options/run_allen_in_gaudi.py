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
from Configurables import Brunel
from Configurables import (TrackSys, GaudiSequencer)
from Configurables import FTRawBankDecoder
from Configurables import NTupleSvc
from Gaudi.Configuration import appendPostConfigAction
from Configurables import (VPClus, createODIN, DumpRawBanks, DumpUTHits,
                           DumpFTHits, DumpMuonCoords, DumpMuonCommonHits,
                           MuonRec, PrepareMuonHits)
from Configurables import RunAllen, AllenUpdater, AllenToForwardTracks
from Configurables import LHCb__Converters__Track__v1__fromV2TrackV1TrackVector as FromV2TrackV1TrackVector
from Configurables import LHCb__Converters__Track__v1__fromVectorLHCbTrack as FromV1VectorV1Tracks
from Configurables import PrTrackAssociator
from Configurables import TrackResChecker, PrimaryVertexChecker
from Configurables import DumpUTGeometry, DumpFTGeometry, DumpMuonTable
from Configurables import DumpMuonGeometry, DumpVPGeometry
from Configurables import DumpMagneticField, DumpBeamline, DumpUTLookupTables
from Configurables import (VPClus, createODIN, DumpRawBanks, DumpUTHits,
                           DumpFTHits, DumpMuonCoords, DumpMuonCommonHits,
                           MuonRec, PrepareMuonHits)
from Configurables import ApplicationMgr
from Configurables import ProcessPhase
import os

# DDDBtag = "dddb-20171010"
# CondDBtag = "sim-20170301-vc-md100"

# DDDBtag = "dddb-20190223" # for v6 samples
# CondDBtag = "sim-20180530-vc-md100"

# For privately produced v5 samples
DDDBtag = "dddb-20180815"
CondDBtag = "sim-20180530-vc-md100"

Evts_to_Run = 10  # set to -1 to process all

# by default write output to the current directory
output_file = "./"

# if environment variable OUTPUT_DIR was set, write the output there
if "OUTPUT_DIR" in os.environ:
    output_file = os.environ.get('OUTPUT_DIR')

mbrunel = Brunel(
    DataType="Upgrade",
    EvtMax=Evts_to_Run,
    PrintFreq=1,
    WithMC=True,
    Simulation=True,
    OutputType="None",
    DDDBtag=DDDBtag,
    CondDBtag=CondDBtag,
    MainSequence=['ProcessPhase/Reco'],
    RecoSequence=["Decoding", "TrFast"],
    Detectors=["VP", "UT", "FT"],
    InputType="DIGI")

TrackSys().TrackingSequence = ["Decoding", "TrFast"]
TrackSys().TrackTypes = ["Velo", "Upstream", "Forward"]
mbrunel.MainSequence += ['ProcessPhase/MCLinks', 'ProcessPhase/Check']

FTRawBankDecoder("createFTClusters").DecodingVersion = 5

NTupleSvc().Output = ["FILE1 DATAFILE='velo_states.root' TYP='ROOT' OPT='NEW'"]


# Save raw banks in Allen format on the TES
dump_banks = DumpRawBanks(
    BankTypes=["VP", "UT", "FTCluster", "Muon"], DumpToFile=False)
dump_seq = GaudiSequencer("RecoAllenPrepareSeq")
dump_seq.Members += [dump_banks]

# call Allen
allen_seq = GaudiSequencer("RecoAllenSeq")
run_allen = RunAllen()
allen_seq.Members += [run_allen]

# check Allen tracks
checker_seq = GaudiSequencer("AllenForwardChecker")

convert_allen_to_forward_tracks = AllenToForwardTracks(OutputTracks="Allen/Out/ForwardTracksV2")

convert_v2_to_v1_forward = FromV2TrackV1TrackVector(InputTracksName="Allen/Out/ForwardTracksV2", OutputTracksName="Allen/Out/ForwardTracksV1")
trconverter = FromV1VectorV1Tracks("AllenForwardTracks" + "Converter")
trconverter.InputTracksName = "Allen/Out/ForwardTracksV1"
trconverter.OutputTracksName = "Allen/Out/ForwardTracksConverted"

trassociator = PrTrackAssociator("AAssociator")
trassociator.SingleContainer = "Allen/Out/ForwardTracksConverted"
trassociator.OutputLocation = "Link/" + "Allen/Out/ForwardTracksConverted"

checker_seq.Members += [convert_allen_to_forward_tracks, convert_v2_to_v1_forward, trconverter, trassociator]

ApplicationMgr().TopAlg += []

producers = [p(DumpToFile=False) for p in (DumpVPGeometry,
                           DumpUTGeometry,
                           DumpFTGeometry,
                           DumpMuonGeometry,
                           DumpMuonTable,
                           DumpMagneticField,
                           DumpBeamline,
                           DumpUTLookupTables)]


# Add the services that will produce the non-event-data
ApplicationMgr().ExtSvc += [
    AllenUpdater(OutputLevel=2),
] + producers



# remove algorithms that are not needed
def modifySequences():
    try:
        # empty the calo sequence
        GaudiSequencer("MCLinksCaloSeq").Members = []
        ProcessPhase("Reco").DetectorList += ["AllenPrepare", "Allen"]
        GaudiSequencer("MCLinksTrSeq").Members += [checker_seq]
        #        GaudiSequencer("MCLinksCaloSeq").Members = []
        # from Configurables import TrackResChecker
        GaudiSequencer("CheckPatSeq").Members.remove(
            TrackResChecker("TrackResCheckerFast"))
        GaudiSequencer("CheckPatSeq").Members.remove(
            PrimaryVertexChecker("PVChecker"))
        # from Configurables import VectorOfTracksFitter
        # GaudiSequencer("RecoTrFastSeq").Members.remove(
        #     VectorOfTracksFitter("ForwardFitterAlgFast"))
        # from Configurables import PrTrackAssociator
        # GaudiSequencer("ForwardFastFittedExtraChecker").Members.remove(
        #     PrTrackAssociator("ForwardFastFittedAssociator"))
        from Configurables import MuonRec
        GaudiSequencer("RecoDecodingSeq").Members.append(MuonRec())
    except ValueError:
        None


appendPostConfigAction(modifySequences)

from Configurables import PrTrackChecker, PrUTHitChecker
def addPrCheckerCutsAndPlots():
    forwardcuts =  {
        "Long_eta25_electrons" : "isLong & isElectron & eta25",
        "Long_eta25_triggerNumbers_electrons" : "isLong & isElectron & eta25 & trigger",
        "LongFromB_eta25_electrons" : "(isLong) & fromB & isElectron & eta25",
        "LongFromD_eta25_electrons" : "(isLong) & fromD & isElectron & eta25",
        "LongStrange_eta25_electrons" : "(isLong) & strange & isElectron & eta25",
        "Long_eta25_notElectrons" : "isLong & isNotElectron & eta25",
        "Long_eta25_triggerNumbers_notElectrons" : "isLong & isNotElectron & eta25 & trigger",
        "LongFromB_eta25_notElectrons" : "(isLong) & fromB & isNotElectron & eta25",
        "LongFromD_eta25_notElectrons" : "(isLong) & fromD & isNotElectron & eta25",
        "LongStrange_eta25_notElectrons" : "(isLong) & strange & isNotElectron & eta25"
    }
    forwardChecker = PrTrackChecker(
        "ForwardMCChecker",
        Title="Forward baseline",
        Tracks="Rec/Track/Keyed/ForwardFast",
        Links="Link/Rec/Track/Keyed/ForwardFast",
        HitTypesToCheck=8,
        WriteHistos = 2,
        VetoElectrons = False,
        MyCuts = forwardcuts
    )
    forwardCheckerAllen = PrTrackChecker(
        "ForwardMCChecker",
        Title="Forward Allen",
        Tracks="Allen/Out/ForwardTracksConverted",
        Links="Link/" + "Allen/Out/ForwardTracksConverted",
        HitTypesToCheck=8,
        WriteHistos = 2,
        VetoElectrons = False,
        MyCuts = forwardcuts
    )
    
    # as configurations are not yet uniformized and properly handled, there is an ugly trick here
    # all members are newly defined here as they have different names from the original ones
    # defined in PrUpgradechecking, but the last one that we reuse as it
    GaudiSequencer("CheckPatSeq").Members = [forwardChecker, forwardCheckerAllen]

appendPostConfigAction( addPrCheckerCutsAndPlots )
