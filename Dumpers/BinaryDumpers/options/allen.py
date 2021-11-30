#!/usr/bin/env python3
###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os
from GaudiPython.Bindings import AppMgr, gbl
from Configurables import LHCbApp, CondDB, ApplicationMgr
from Allen.config import setup_allen_non_event_data_service
from threading import Thread
from time import sleep
import ctypes
import argparse

# Load Allen entry point and helpers
gbl.gSystem.Load("libAllenLib")
gbl.gSystem.Load("libBinaryDumpers")
interpreter = gbl.gInterpreter

# FIXME: Once the headers are installed properly, this should not be
# necessary anymore
allen_dir = os.environ["ALLEN_PROJECT_ROOT"]
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
parser.add_argument("-n", dest="n_events", default=0)
parser.add_argument("-t", dest="threads", default=1)
parser.add_argument("-r", dest="repetitions", default=1)
parser.add_argument("-m", dest="reserve", default=1024)
parser.add_argument("-v", dest="verbosity", default=3)
parser.add_argument("-p", dest="print_memory", default=0)
parser.add_argument("--sequence", dest="sequence", default=sequence_default)
parser.add_argument("-s", dest="slices", default=2)
parser.add_argument(
    "--mdf",
    dest="mdf",
    default=os.path.join(allen_dir, "input", "minbias", "mdf",
                         "upgrade_mc_minbias_scifi_v5.mdf"))
parser.add_argument("--mep", dest="mep", default=None)
parser.add_argument(
    "--reuse-meps",
    action="store_true",
    dest="reuse_meps",
    default=False,
    help="Fill all MEP buffers once and then reuse them",
)
parser.add_argument(
    "--cpu-offload",
    dest="cpu_offload",
    default=1,
    help="Offload some operations to the CPU",
)
parser.add_argument(
    "--profile",
    dest="profile",
    type=str,
    default="",
    choices=["", "CUDA"],
    help="Add profiler start and stop calls",
)
parser.add_argument("--output-file", dest="output_file", default=None)
parser.add_argument(
    "--monitoring-save-period", dest="mon_save_period", default=0)
parser.add_argument(
    "--monitoring-filename",
    dest="mon_filename",
    default="",
    help="Histogram filename")
parser.add_argument(
    "--enable-run-changes",
    dest="enable_run_changes",
    action="store_true",
    default=False,
)
parser.add_argument(
    "--events-per-slice",
    dest="events_per_slice",
    default=1000,
    help="number of events per batch submitted to the GPU",
)
parser.add_argument("--device", dest="device", default=0, help="Device index")
parser.add_argument(
    "--runtime",
    dest="runtime",
    type=int,
    default=300,
    help="How long to run when reusing MEPs",
)

args = parser.parse_args()

default_configuration = os.path.join(os.environ['ALLEN_INSTALL_DIR'],
                                     'constants' + args.sequence + '.json')

runtime_lib = None
if args.profile == "CUDA":
    runtime_lib = ctypes.CDLL("libcudart.so")

app = LHCbApp(
    DataType="Upgrade",
    EvtMax=1000,
    Simulation=True,
    DDDBtag="dddb-20171122",
    CondDBtag="sim-20180530-vc-md100")
    # DDDBtag="dddb-20210617",  # tags for FEST sample from 10/2021
    # CondDBtag="sim-20210617-vc-md100")

# Upgrade DBs
CondDB().Upgrade = True

setup_allen_non_event_data_service()

# Some extra stuff for timing table
ApplicationMgr().EvtSel = "NONE"
ApplicationMgr().ExtSvc += ["ToolSvc", "AuditorSvc", "ZeroMQSvc"]

if args.mep is not None:
    ApplicationMgr().ExtSvc += ["MEPProvider"]
    from Configurables import MEPProvider

    mep_provider = MEPProvider()
    mep_provider.NSlices = args.slices
    mep_provider.EventsPerSlice = args.events_per_slice
    mep_provider.OutputLevel = 2
    # Number of MEP buffers and number of transpose/offset threads
    mep_provider.BufferConfig = (10, 8)
    mep_provider.TransposeMEPs = False
    mep_provider.SplitByRun = False
    mep_provider.Source = "Files"
    mep_dir = args.mep
    if os.path.isdir(mep_dir):
        mep_provider.Connections = sorted([
            os.path.join(mep_dir, mep_file) for mep_file in os.listdir(mep_dir)
            if mep_file.endswith(".mep")
        ])
    else:
        mep_provider.Connections = mep_dir.split(',')
    mep_provider.LoopOnMEPs = False
    mep_provider.Preload = args.reuse_meps
    # Use this property to allocate buffers to specific NUMA domains
    # to test the effects on performance or emulate specific memory
    # traffic scenarios
    # mep_provider.BufferNUMA = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
    mep_provider.EvtMax = -1 if args.n_events == 0 else args.n_events

# Start Gaudi and get the AllenUpdater service
gaudi = AppMgr()
gaudi.initialize()
svc = gaudi.service("AllenUpdater", interface=gbl.IService)
zmqSvc = gaudi.service("ZeroMQSvc", interface=gbl.IZeroMQSvc)

updater = cast_service(gbl.Allen.NonEventData.IUpdater, svc)

# options map
options = gbl.std.map("std::string", "std::string")()
for flag, value in [("g", args.det_folder), ("params", args.param_folder),
                    ("n", args.n_events), ("t", args.threads),
                    ("r", args.repetitions), ("output-file", args.output_file),
                    ("m", args.reserve), ("v", args.verbosity),
                    ("p", args.print_memory), ("sequence", args.sequence),
                    ("s", args.slices), ("mdf", args.mdf),
                    ("cpu-offload", args.cpu_offload),
                    ("disable-run-changes", int(not args.enable_run_changes)),
                    ("monitoring-save-period", args.mon_save_period),
                    ("monitoring-filename", args.mon_filename),
                    ("events-per-slice", args.events_per_slice),
                    ("device", args.device), ("run-from-json", "1")]:
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
gbl.allen.__release_gil__ = 1


def sleep_fun():
    print("sleeping")
    sleep(args.runtime)
    gaudi.stop()


if args.reuse_meps:
    sleep_thread = Thread(target=sleep_fun)
    sleep_thread.start()

if args.profile == "CUDA":
    runtime_lib.cudaProfilerStart()
gbl.allen(options, updater, provider, output_handler, zmqSvc, con.c_str())
if args.profile == "CUDA":
    runtime_lib.cudaProfilerStop()

if args.reuse_meps:
    sleep_thread.join()
