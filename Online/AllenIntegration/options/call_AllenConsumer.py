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
from Configurables import AllenConsumer, AllenUpdater
from Configurables import DumpUTGeometry, DumpFTGeometry, DumpMuonTable
from Configurables import DumpMuonGeometry, DumpVPGeometry, AllenUpdater
from Configurables import DumpMagneticField, DumpBeamline, DumpUTLookupTables 
from Configurables import ApplicationMgr
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
