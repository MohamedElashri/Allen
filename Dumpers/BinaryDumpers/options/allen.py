#!/usr/bin/env python3
###############################################################################
# (c) Copyright 2018-2021 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os
import sys
import zmq
from Configurables import ApplicationMgr
from Configurables import Gaudi__RootCnvSvc as RootCnvSvc
from Allen.config import setup_allen_non_event_data_service
from PyConf.application import (configure, setup_component, ComponentConfig,
                                ApplicationOptions)
from threading import Thread
from time import sleep
import ctypes
import argparse
from GaudiPython.Bindings import AppMgr, gbl

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
                                'hlt1_pp_default.json')


def cast_service(return_type, svc):
    return gbl.cast_service(return_type)()(svc)


def shared_wrap(return_type, t):
    return gbl.shared_wrap(return_type)()(t)


# Handle commandline arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "-g",
    dest="det_folder",
    default=os.path.join(allen_dir, "input", "detector_configuration"))
parser.add_argument("-n", dest="n_events", default=0)
parser.add_argument("-t", dest="threads", default=1)
parser.add_argument("-r", dest="repetitions", default=1)
parser.add_argument("-m", dest="reserve", default=1024)
parser.add_argument("-v", dest="verbosity", default=3)
parser.add_argument("-p", dest="print_memory", default=0)
parser.add_argument("--sequence", dest="sequence", default=sequence_default)
parser.add_argument("-s", dest="slices", default=2)
parser.add_argument("--mdf", dest="mdf", default="")
parser.add_argument("--mep", dest="mep", default="")
parser.add_argument(
    "--mep-mask-source-id-top-5",
    action="store_true",
    dest="mask_top5",
    default=False)
parser.add_argument(
    "--reuse-meps",
    action="store_true",
    dest="reuse_meps",
    default=False,
    help="Fill all MEP buffers once and then reuse them",
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
    "--output-batch-size", dest="output_batch_size", default=10)
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
    help="How long to run when reusing MEPs [s]",
)
parser.add_argument(
    "--tags", dest="tags", default="dddb-20171122,sim-20180530-vc-md100")
parser.add_argument(
    "--enable-monitoring-printing",
    dest="enable_monitoring_printing",
    type=int,
    default=False,
    help="Enables printing monitoring information",
)
parser.add_argument(
    "--register-monitoring-counters",
    dest="register_monitoring_counters",
    type=int,
    default=True,
    help="Enables printing counters information",
)

args = parser.parse_args()

runtime_lib = None
if args.profile == "CUDA":
    runtime_lib = ctypes.CDLL("libcudart.so")

dddb_tag, conddb_tag = args.tags.split(',')

options = ApplicationOptions(_enabled=False)
options.simulation = True
options.data_type = 'Upgrade'
options.input_type = 'MDF'
options.dddb_tag = dddb_tag
options.conddb_tag = conddb_tag

options.finalize()
config = ComponentConfig()

# Some extra stuff for timing table
extSvc = ["ToolSvc", "AuditorSvc", "ZeroMQSvc"]

# RootCnvSvc becauce it sets up a bunch of ROOT IO stuff
rootSvc = RootCnvSvc("RootCnvSvc", EnableIncident=1)
ApplicationMgr().ExtSvc += ["Gaudi::IODataManager/IODataManager", rootSvc]

if args.mep:
    extSvc += ["AllenConfiguration", "MEPProvider"]
    from Configurables import MEPProvider, AllenConfiguration

    allen_conf = AllenConfiguration("AllenConfiguration")
    allen_conf.JSON = args.sequence
    allen_conf.OutputLevel = 3

    mep_provider = MEPProvider()
    mep_provider.NSlices = args.slices
    mep_provider.EventsPerSlice = args.events_per_slice
    mep_provider.OutputLevel = (6 - int(args.verbosity))
    # Number of MEP buffers and number of transpose/offset threads
    mep_provider.BufferConfig = (10, 8)
    mep_provider.TransposeMEPs = False
    mep_provider.SplitByRun = False
    mep_provider.Source = "Files"
    mep_provider.MaskSourceIDTop5 = args.mask_top5
    mep_dir = os.path.expandvars(args.mep)
    if os.path.isdir(mep_dir):
        mep_provider.Connections = sorted([
            os.path.join(mep_dir, mep_file) for mep_file in os.listdir(mep_dir)
            if mep_file.endswith(".mep")
        ])
    else:
        mep_provider.Connections = mep_dir.split(',')
    # mep_provider.Connections = ["/daqarea1/fest/beam_test/Allen_BU_10.mep"]

    mep_provider.LoopOnMEPs = False
    mep_provider.Preload = args.reuse_meps
    # Use this property to allocate buffers to specific NUMA domains
    # to test the effects on performance or emulate specific memory
    # traffic scenarios
    # mep_provider.BufferNUMA = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
    mep_provider.EvtMax = -1 if args.n_events == 0 else args.n_events

ApplicationMgr().EvtSel = "NONE"
ApplicationMgr().ExtSvc += extSvc

# Copeid from PyConf.application.configure_input
config.add(
    setup_component(
        'DDDBConf', Simulation=options.simulation, DataType=options.data_type))
config.add(
    setup_component(
        'CondDB',
        Upgrade=True,
        Tags={
            'DDDB': options.dddb_tag,
            'SIMCOND': options.conddb_tag,
        }))

cf_node = setup_allen_non_event_data_service(allen_event_loop=True)
config.update(configure(options, cf_node))

# Start Gaudi and get the AllenUpdater service
gaudi = AppMgr()
sc = gaudi.initialize()
if not sc.isSuccess():
    sys.exit("Failed to initialize AppMgr")

svc = gaudi.service("AllenUpdater", interface=gbl.IService)
zmqSvc = gaudi.service("ZeroMQSvc", interface=gbl.IZeroMQSvc)

updater = cast_service(gbl.Allen.NonEventData.IUpdater, svc)

# options map
options = gbl.std.map("std::string", "std::string")()
for flag, value in [("g", args.det_folder),
                    ("params", os.getenv("PARAMFILESROOT")),
                    ("n", args.n_events), ("t", args.threads),
                    ("r", args.repetitions), ("output-file", args.output_file),
                    ("output-batch-size", args.output_batch_size),
                    ("m", args.reserve), ("v", args.verbosity),
                    ("p", args.print_memory),
                    ("sequence", os.path.expandvars(args.sequence)),
                    ("s", args.slices), ("mdf", os.path.expandvars(args.mdf)),
                    ("disable-run-changes", int(not args.enable_run_changes)),
                    ("monitoring-save-period", args.mon_save_period),
                    ("monitoring-filename", args.mon_filename),
                    ("events-per-slice", args.events_per_slice),
                    ("device", args.device), ("run-from-json", "1"),
                    ("enable-monitoring-printing",
                     args.enable_monitoring_printing),
                    ("register-monitoring-counters",
                     args.register_monitoring_counters)]:
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

# run Allen
gbl.allen.__release_gil__ = 1

# get the libzmq context out of the zmqSvc and use it to instantiate
# the pyzmq Context
cpp_ctx = zmqSvc.context()
c_ctx = gbl.czmq_context(cpp_ctx)
ctx = zmq.Context.shadow(c_ctx)

ctx.linger = -1
control = ctx.socket(zmq.PAIR)

if args.reuse_meps:
    gaudi.start()
else:
    # C++ and python strings
    connection = "inproc:///py_allen_control"
    con = gbl.std.string(connection)
    control.bind(connection)


# Call the main Allen function from a thread so we can control it from
# the main thread
def allen_thread():
    if args.profile == "CUDA":
        runtime_lib.cudaProfilerStart()

    gbl.allen(options, updater, shared_wrap(gbl.IInputProvider, provider),
              output_handler, zmqSvc, con.c_str())

    if args.profile == "CUDA":
        runtime_lib.cudaProfilerStop()


allen_thread = Thread(target=allen_thread)
allen_thread.start()

if args.reuse_meps:
    print("sleeping")
    sleep(args.runtime)
    gaudi.stop()
else:
    # READY
    msg = control.recv()
    assert (msg.decode() == "READY")
    gaudi.start()
    control.send(b"START")
    msg = control.recv()
    assert (msg.decode() == "RUNNING")
    sleep(5)
    r = control.poll(0)
    if r == zmq.POLLIN:
        msg = control.recv()
        if msg.decode() == "ERROR":
            print("ERROR from Allen event loop")
            allen_thread.join()
            sys.exit(1)

    control.send(b"STOP")
    gaudi.stop()
    msg = control.recv()
    assert (msg.decode() == "READY")
    if args.profile == "CUDA":
        runtime_lib.cudaProfilerStop()
    gaudi.finalize()
    control.send(b"RESET")
    msg = control.recv()
    assert (msg.decode() == "NOT_READY")

allen_thread.join()
