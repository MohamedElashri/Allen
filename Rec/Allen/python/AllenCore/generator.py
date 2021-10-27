###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.application import default_raw_event
from PyConf.Algorithms import (
    ProvideConstants,
    TransposeRawBanks,
    ProvideRuntimeOptions,
    host_init_event_list_t,
)
from GaudiKernel.DataHandle import DataHandle


# Additional algorithms required by every Gaudi-Allen sequence
def make_transposed_raw_banks(make_raw=default_raw_event):
    return TransposeRawBanks(RawEventLocations=[
        make_raw(bank_types=[k]) for k in
        ["ODIN", "Muon", "FTCluster", "UT", "VP", "EcalPacked", "HcalPacked"]
    ]).AllenRawInput


def get_runtime_options():
    return ProvideRuntimeOptions(
        AllenBanksLocation=make_transposed_raw_banks())


def get_constants():
    return ProvideConstants()


# Gaudi configuration wrapper
def make_algorithm(algorithm, *args, **kwargs):
    rto = get_runtime_options()
    cs = get_constants()
    dev_event_list = host_init_event_list_t(
        name="make_event_list", runtime_options_t=rto,
        constants_t=cs).dev_event_list_output_t
    # Pass dev_event_list to inputs that are of type dev_event_list
    event_list_names = [
        k for k, w in algorithm.getDefaultProperties().items()
        if isinstance(w, DataHandle) and dev_event_list.type == w.type()
        and w.mode() == "R"
    ]
    for dev_event_list_name in event_list_names:
        kwargs[dev_event_list_name] = dev_event_list
    return algorithm(runtime_options_t=rto, constants_t=cs, *args, **kwargs)
