#!/usr/bin/env python2
import HeaderPath
from GaudiPython.Bindings import AppMgr, gbl
from Configurables import LHCbApp, CondDB, ApplicationMgr
from Configurables import DumpUTGeometry, DumpFTGeometry, DumpMuonTable
from Configurables import DumpMuonGeometry, DumpVPGeometry, AllenUpdater
from Configurables import DumpMagneticField, DumpBeamline, DumpUTLookupTables
import argparse

# Load Allen entry point and helpers
gbl.gSystem.Load("libAllenLib")
gbl.gSystem.Load("libBinaryDumpersLib")
interpreter = gbl.gInterpreter
interpreter.Declare("#include <main/include/Allen.h>")
interpreter.Declare("#include <Dumpers/PyAllenHelper.h>")

# Handle commandline arguments
parser = argparse.ArgumentParser(usage=('usage: %(prog)s app'
                                        ' <node|subfarm|top> <runtime[s]>'))
parser.add_argument("-f", dest="folder", default="../input/minbias")
parser.add_argument("-g", dest="det_folder",
                    default="../input/detector_configuration/down")
parser.add_argument("-n", dest="n_events",  default="0")
parser.add_argument("-o", dest="event_offset", default="0")
parser.add_argument("-t", dest="threads", default="1")
parser.add_argument("-r", dest="repetitions", default="1")
parser.add_argument("-c", dest="check", default="1")
parser.add_argument("-m", dest="reserve", default="1024")
parser.add_argument("-v", dest="verbosity", default="3")
parser.add_argument("-p", dest="print_memory", default="0")
parser.add_argument("-i", dest="import_fwd", default="")
parser.add_argument("--mdf", dest="mdf", default="")
parser.add_argument("--cpu-offload", dest="cpu_offload", default="1")
parser.add_argument("--device", dest="device", default="0")

args = parser.parse_args()

app = LHCbApp(
    DataType="Upgrade",
    EvtMax=1000,
    Simulation=True,
    DDDBtag="dddb-20171122",
    CondDBtag="sim-20180530-vc-md100")

# Upgrade DBs
CondDB().Upgrade = True

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

# Some extra stuff for timing table
ApplicationMgr().EvtSel = "NONE"
ApplicationMgr().ExtSvc += ['ToolSvc', 'AuditorSvc']

# Start Gaudi and get the AllenUpdater service
gaudi = AppMgr()
gaudi.initialize()
svc = gaudi.service("AllenUpdater", interface=gbl.IService)


updater = gbl.cast_updater(svc)

# options map
options = gbl.std.map("std::string", "std::string")()
for flag, value in (("f", args.folder),
                    ("g", args.det_folder),
                    ("n", args.n_events),
                    ("o", args.event_offset),
                    ("t", args.threads),
                    ("r", args.repetitions),
                    ("c", args.check),
                    ("m", args.reserve),
                    ("v", args.verbosity),
                    ("p", args.print_memory),
                    ("i", args.import_fwd),
                    ("mdf", args.mdf),
                    ("cpu-offload", args.cpu_offload),
                    ("device", args.device)):
    options[flag] = value

# run Allen
gbl.allen(options, updater)
