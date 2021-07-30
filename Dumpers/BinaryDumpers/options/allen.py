#!/usr/bin/env python3
###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os
from functools import partial
from Configurables import LHCbApp, CondDB, ApplicationMgr
from Allen.config import setup_allen_non_event_data_service
from GaudiPython.Bindings import AppMgr, gbl
import argparse

# Load Allen entry point and helpers
gbl.gSystem.Load("libAllenLib")
gbl.gSystem.Load("libBinaryDumpers")
interpreter = gbl.gInterpreter

# FIXME: Once the headers are installed properly, this should not be
# necessary anymore
allen_dir = os.environ['ALLEN_PROJECT_ROOT']
interpreter.Declare("#include <Dumpers/IUpdater.h>")
interpreter.Declare("#include <Allen/Allen.h>")
interpreter.Declare("#include <Allen/Provider.h>")
interpreter.Declare("#include <Dumpers/PyAllenHelper.h>")

sequence_default = os.path.join(os.environ['ALLEN_INSTALL_DIR'], 'constants',
                                'hlt1_pp_default')


def cast_service(return_type, svc):
    return gbl.cast_service(return_type)()(svc)


# Handle commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "-g",
    dest="det_folder",
    default=os.path.join(allen_dir, "input", "detector_configuration", "down"))
parser.add_argument(
    "--params",
    dest="param_folder",
    default=os.path.join(allen_dir, "input", "parameters"))
parser.add_argument("-n", dest="n_events", default="0")
parser.add_argument("-t", dest="threads", default="1")
parser.add_argument("-r", dest="repetitions", default="1")
parser.add_argument("-m", dest="reserve", default="1024")
parser.add_argument("-v", dest="verbosity", default="3")
parser.add_argument("-p", dest="print_memory", default="0")
parser.add_argument("-i", dest="import_fwd", default="")
parser.add_argument("--sequence", dest="sequence", default=sequence_default)
parser.add_argument("-s", dest="slices", default="2")
parser.add_argument("-b", "--bank-types", dest="bank_types",
                    default="VP,FTCluster,UT,Muon,ODIN")
parser.add_argument(
    "--mdf",
    dest="mdf",
    default=os.path.join(allen_dir, "input", "minbias", "mdf",
                         "upgrade_mc_minbias_scifi_v5.mdf"))
parser.add_argument("--cpu-offload", dest="cpu_offload", default="1")
parser.add_argument(
    "--output-file", dest="output_file", default=None)
parser.add_argument(
    "--monitoring-save-period", dest="mon_save_period", default=0)
parser.add_argument(
    "--monitoring-filename",
    dest="mon_filename",
    default="monitoringHists.root", help="Histogram filename")
parser.add_argument(
    "--disable-run-changes", dest="disable_run_changes", default=1)
parser.add_argument(
    "--events-per-slice", dest="events_per_slice", default=1000,
    help="number of events per batch submitted to the GPU")
parser.add_argument("--device", dest="device", default=0, help="Device index")

args = parser.parse_args()

app = LHCbApp(
    DataType="Upgrade",
    EvtMax=1000,
    Simulation=True,
    DDDBtag="dddb-20210218",
    CondDBtag="sim-20201218-vc-md100")

# Upgrade DBs
CondDB().Upgrade = True

setup_allen_non_event_data_service()

# Some extra stuff for timing table
ApplicationMgr().EvtSel = "NONE"
ApplicationMgr().ExtSvc += ['ToolSvc', 'AuditorSvc', 'ZeroMQSvc']

if args.mep is not None:
    ApplicationMgr().ExtSvc += ['MEPProvider']
    from Configurables import MEPProvider

    mep_provider = MEPProvider()
    mep_provider.NSlices = args.slices
    mep_provider.EventsPerSlice = 1000
    mep_provider.OutputLevel = 2
    # Number of MEP buffers and number of transpose/offset threads
    mep_provider.BufferConfig = (4, 3)
    mep_provider.TransposeMEPs = False
    mep_provider.SplitByRun = False
    mep_provider.Source = "Files"
    mep_dir = args.mep
    mep_provider.Connections = sorted([os.path.join(mep_dir, mep_file)
                                       for mep_file in os.listdir(mep_dir)
                                       if mep_file.endswith('.mep')])
    mep_provider.LoopOnMEPs = False
    mep_provider.Preload = True
    mep_provider.EvtMax = 50000
    mep_provider.BufferNUMA = [0, 0, 1, 1]

# Start Gaudi and get the AllenUpdater service
gaudi = AppMgr()
gaudi.initialize()
svc = gaudi.service("AllenUpdater", interface=gbl.IService)
zmqSvc = gaudi.service("ZeroMQSvc", interface=gbl.IZeroMQSvc)

updater = cast_service(gbl.Allen.NonEventData.IUpdater, svc)

# options map
options = gbl.std.map("std::string", "std::string")()
for flag, value in (("g", args.det_folder), ("params", args.param_folder),
                    ("n", args.n_events),
                    ("t", args.threads), ("r", args.repetitions),
                    ("output-file", args.output_file),
                    ("m", args.reserve), ("v", args.verbosity),
                    ("p", args.print_memory), ("i", args.import_fwd),
                    ("sequence", args.sequence),
                    ("s", args.slices), ("mdf", args.mdf),
                    ("b", args.bank_types),
                    ("cpu-offload", args.cpu_offload),
                    ("disable-run-changes", args.disable_run_changes),
                    ("monitoring-save-period", args.mon_save_period),
                    ("monitoring-filename", args.mon_filename),
                    ("events-per-slice", args.events_per_slice),
                    ("device", args.device), ("run-from-json", "1")):
    if value is not None:
        options[flag] = str(value)

con = gbl.std.string("")

# Create provider
if args.mep:
    mep_provider = gaudi.service("MEPProvider", interface=gbl.IService)
    provider = cast_service(gbl.IInputProvider, mep_provider)
else:
    provider = gbl.Allen.make_provider(options)
output_handler = gbl.Allen.output_handler(provider, zmqSvc, options)

gaudi.start()

# run Allen
gbl.allen(options, updater, provider, output_handler, zmqSvc, con.c_str())
