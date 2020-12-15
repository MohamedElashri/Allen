###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from Configurables import Brunel
from Configurables import (TrackSys, GaudiSequencer)
from Configurables import FTRawBankDecoder
from Configurables import NTupleSvc
from Gaudi.Configuration import appendPostConfigAction

# DDDBtag = "dddb-20171010"
# CondDBtag = "sim-20170301-vc-md100"

# For privately produced minbias and BsPhiPhi
# in /eos/lhcb/wg/SciFi/Simulation/MinBiasRawBankv5/
# and /eos/lhcb/wg/SciFi/Simulation/RawBanksv5/
DDDBtag = "dddb-20180815"
CondDBtag = "sim-20180530-vc-md100"

Evts_to_Run = 1000  # set to -1 to process all

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


def modifySequences():
    try:
        # empty the calo sequence
        GaudiSequencer("MCLinksCaloSeq").Members = []
        #        GaudiSequencer("MCLinksCaloSeq").Members = []
        from Configurables import TrackResChecker
        GaudiSequencer("CheckPatSeq").Members.remove(
            TrackResChecker("TrackResCheckerFast"))
        from Configurables import VectorOfTracksFitter
        GaudiSequencer("RecoTrFastSeq").Members.remove(
            VectorOfTracksFitter("ForwardFitterAlgFast"))
        from Configurables import PrTrackAssociator
        GaudiSequencer("ForwardFastFittedExtraChecker").Members.remove(
            PrTrackAssociator("ForwardFastFittedAssociator"))
        from Configurables import MuonRec
        GaudiSequencer("RecoDecodingSeq").Members.append(MuonRec())
    except ValueError:
        None


appendPostConfigAction(modifySequences)


def AddDumpers():
    from Configurables import PrTrackerDumper, DumpVeloUTState, PVDumper
    dump_mc = PrTrackerDumper(
        "DumpMCInfo", DumpToBinary=True, DumpToROOT=False)
    #dump_mc.OutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/TrackerDumper"
    #dump_mc.MCOutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/MC_info/tracks"
    dump_pvmc = PVDumper("DumpPVMCInfo")
    #dump_pvmc.OutputDirectory = "/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/mag_down/MC_info/PVs"
    GaudiSequencer("MCLinksTrSeq").Members += [dump_mc, dump_pvmc]


appendPostConfigAction(AddDumpers)
