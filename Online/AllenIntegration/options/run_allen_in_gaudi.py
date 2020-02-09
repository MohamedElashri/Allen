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
from Configurables import RunAllen, AllenUpdater, AllenForwardToV2Tracks, AllenVeloToV2Tracks, AllenUTToV2Tracks
from Configurables import LHCb__Converters__Track__v1__fromV2TrackV1TrackVector as FromV2TrackV1TrackVector
from Configurables import LHCb__Converters__Track__v1__fromVectorLHCbTrack as FromV1VectorV1Tracks
from Configurables import LHCb__Converters__Track__v1__fromV2TrackV1Track as FromV2TrackV1Track
from Configurables import PrTrackAssociator
from Configurables import TrackResChecker, PrimaryVertexChecker
from Configurables import DumpUTGeometry, DumpFTGeometry, DumpMuonTable
from Configurables import DumpMuonGeometry, DumpVPGeometry
from Configurables import DumpMagneticField, DumpBeamline, DumpUTLookupTables
from Configurables import ApplicationMgr
from Configurables import ProcessPhase

import os

MCCuts = {
    "Velo": {
        "01_velo": "isVelo",
        "02_long": "isLong",
        "03_long_P>5GeV": "isLong & over5",
        "04_long_strange": "isLong & strange",
        "05_long_strange_P>5GeV": "isLong & strange & over5",
        "06_long_fromB": "isLong & fromB",
        "07_long_fromB_P>5GeV": "isLong & fromB & over5",
        "08_long_electrons": "isLong & isElectron",
        "09_long_fromB_electrons": "isLong & isElectron & fromB",
        "10_long_fromB_electrons_P_P>5GeV":
        "isLong & isElectron & over5 & fromB",
        "11_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger",
        "12_UT_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger & isUT"
    },
    "Forward": {
        "01_long": "isLong",
        "02_long_P>5GeV": "isLong & over5",
        "03_long_strange": "isLong & strange",
        "04_long_strange_P>5GeV": "isLong & strange & over5",
        "05_long_fromB": "isLong & fromB",
        "06_long_fromB_P>5GeV": "isLong & fromB & over5",
        "07_long_electrons": "isLong & isElectron",
        "08_long_electrons_P_P>5GeV": "isLong & isElectron & over5",
        "09_long_fromB_electrons": "isLong & isElectron & fromB",
        "10_long_fromB_electrons_P_P>5GeV":
        "isLong & isElectron & over5 & fromB",
        "10_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger",
        "11_UT_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger & isUT"
    },
    "Upstream": {
        "01_velo": "isVelo",
        "02_velo+UT": "isVelo & isUT",
        "03_velo+UT_P>5GeV": "isVelo & isUT & over5",
        "04_velo+notLong": "isNotLong & isVelo ",
        "05_velo+UT+notLong": "isNotLong & isVelo & isUT",
        "06_velo+UT+notLong_P>5GeV": "isNotLong & isVelo & isUT & over5",
        "07_long": "isLong",
        "08_long_P>5GeV": "isLong & over5 ",
        "09_long_fromB": "isLong & fromB",
        "10_long_fromB_P>5GeV": "isLong & fromB & over5",
        "11_long_electrons": "isLong & isElectron",
        "12_long_fromB_electrons": "isLong & isElectron & fromB",
        "13_long_fromB_electrons_P_P>5GeV":
        "isLong & isElectron & over5 & fromB",
        "14_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger",
        "15_UT_long_fromB_P>3GeV_Pt>0.5GeV": "isLong & fromB & trigger & isUT"
    }
}


def getMCCuts(key):
    cuts = dict(MCCuts[key]) if key in MCCuts else {}
    return cuts


# Has to mirror the enum HitType in PrTrackCounter.h
HitType = {"VP": 3, "UT": 4, "FT": 8}


def getHitTypeMask(dets):
    mask = 0
    for det in dets:
        if det not in HitType:
            log.warning(
                "Hit type to check unknown. Ignoring hit type, counting all.")
            return 0
        mask += HitType[det]

    return mask


# For privately produced v5 samples
DDDBtag = "dddb-20180815"
CondDBtag = "sim-20180530-vc-md100"

Evts_to_Run = 1000  # set to -1 to process all

# by default write output to the current directory
output_file = "./"

# if environment variable OUTPUT_DIR was set, write the output there
if "OUTPUT_DIR" in os.environ:
    output_file = os.environ.get('OUTPUT_DIR')

mbrunel = Brunel(
    DataType="Upgrade",
    EvtMax=Evts_to_Run,
    #SkipEvents = 20,
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
outputdirectory = "dump/"
dump_banks = DumpRawBanks(
    BankTypes=["VP", "UT", "FTCluster", "Muon", "ODIN"],
    DumpToFile=False,
    OutputDirectory=outputdirectory + "banks")
dump_seq = GaudiSequencer("RecoAllenPrepareSeq")
dump_seq.Members += [dump_banks]

# call Allen
allen_seq = GaudiSequencer("RecoAllenSeq")
run_allen = RunAllen()
allen_seq.Members += [run_allen]

# check Allen tracks
tracksToConvert = ["Velo", "Upstream", "Forward"]
checker_seq = GaudiSequencer("AllenChecker")

allen_velo_to_v2 = AllenVeloToV2Tracks(OutputTracks="Allen/Track/v2/Velo")
allen_ut_to_v2 = AllenUTToV2Tracks(OutputTracks="Allen/Track/v2/Upstream")
allen_forward_to_v2 = AllenForwardToV2Tracks(
    OutputTracks="Allen/Track/v2/Forward")
checker_seq.Members += [allen_velo_to_v2, allen_ut_to_v2, allen_forward_to_v2]

for tracktype in tracksToConvert:
    trconverter = FromV2TrackV1Track("Allen" + tracktype + "Converter")
    trconverter.InputTracksName = "Allen/Track/v2/" + tracktype
    trconverter.OutputTracksName = "Allen/Track/v1/" + tracktype + "Converted"
    checker_seq.Members += [trconverter]

    trassociator = PrTrackAssociator("Allen" + tracktype + "Associator")
    trassociator.SingleContainer = "Allen/Track/v1/" + tracktype + "Converted"
    trassociator.OutputLocation = "Link/" + "Allen/Track/v1/" + tracktype + "Converted"
    checker_seq.Members += [trassociator]

mc_dumper_seq = GaudiSequencer("MCDumper")
from Configurables import PrTrackerDumper, DumpVeloUTState, PVDumper
dump_mc = PrTrackerDumper("DumpMCInfo", DumpToBinary=True, DumpToROOT=False)
dump_mc.OutputDirectory = outputdirectory + "TrackerDumper"
dump_mc.MCOutputDirectory = outputdirectory + "MC_info/tracks"
dump_pvmc = PVDumper("DumpPVMCInfo")
dump_pvmc.OutputDirectory = outputdirectory + "MC_info/PVs"
mc_dumper_seq.Members += [dump_mc, dump_pvmc]

ApplicationMgr().TopAlg += []

producers = [
    p(DumpToFile=False)
    for p in (DumpVPGeometry, DumpUTGeometry, DumpFTGeometry, DumpMuonGeometry,
              DumpMuonTable, DumpMagneticField, DumpBeamline,
              DumpUTLookupTables)
]

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
        GaudiSequencer("CheckPatSeq").Members.remove(
            TrackResChecker("TrackResCheckerFast"))
        GaudiSequencer("CheckPatSeq").Members.remove(
            PrimaryVertexChecker("PVChecker"))
        from Configurables import PrGECFilter
        #GaudiSequencer("RecoDecodingSeq").Members.remove(PrGECFilter())
        from Configurables import MuonRec
        GaudiSequencer("RecoDecodingSeq").Members.append(MuonRec())
    except ValueError:
        None


appendPostConfigAction(modifySequences)

from Configurables import PrTrackChecker, PrUTHitChecker


def addPrCheckerCutsAndPlots():
    veloCheckerAllen = PrTrackChecker(
        "VeloMCChecker",
        Title="Velo Allen",
        Tracks="Allen/Track/v1/VeloConverted",
        Links="Link/" + "Allen/Track/v1/VeloConverted",
        TriggerNumbers=False,
        CheckNegEtaPlot=True,
        HitTypesToCheck=getHitTypeMask(["VP"]),
        MyCuts=getMCCuts("Velo"))
    upCheckerAllen = PrTrackChecker(
        "UpMCChecker",
        Title="Upstream Allen",
        Tracks="Allen/Track/v1/UpstreamConverted",
        Links="Link/" + "Allen/Track/v1/UpstreamConverted",
        TriggerNumbers=True,
        HitTypesToCheck=getHitTypeMask(["UT"]),
        MyCuts=getMCCuts("Upstream"))
    forwardCheckerAllen = PrTrackChecker(
        "ForwardMCChecker",
        Title="Forward Allen",
        Tracks="Allen/Track/v1/ForwardConverted",
        Links="Link/" + "Allen/Track/v1/ForwardConverted",
        TriggerNumbers=True,
        HitTypesToCheck=getHitTypeMask(["FT"]),
        MyCuts=getMCCuts("Forward"))

    # as configurations are not yet uniformized and properly handled, there is an ugly trick here
    # all members are newly defined here as they have different names from the original ones
    # defined in PrUpgradechecking, but the last one that we reuse as it
    GaudiSequencer("CheckPatSeq").Members += [
        veloCheckerAllen, upCheckerAllen, forwardCheckerAllen
    ]


appendPostConfigAction(addPrCheckerCutsAndPlots)
