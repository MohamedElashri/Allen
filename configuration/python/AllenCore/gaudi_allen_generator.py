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
from PyConf.Algorithms import (ProvideConstants, TransposeRawBanks,
                               ProvideRuntimeOptions, host_init_event_list_t,
                               odin_provider_t)
from GaudiKernel.DataHandle import DataHandle
from PyConf import configurable


# Additional algorithms required by every Gaudi-Allen sequence
@configurable
def make_transposed_raw_banks(rawbank_list, make_raw=default_raw_event):
    return TransposeRawBanks(
        RawEventLocations=[make_raw(bank_types=[k]) for k in rawbank_list],
        BankTypes=rawbank_list).AllenRawInput


@configurable
def allen_runtime_options(rawbank_list, filename="allen_monitor.root"):
    from Configurables import AllenROOTService
    rootService = AllenROOTService()
    prop = "MonitorFile"
    value = rootService.getProp(prop)
    if rootService.isPropertySet(prop) and value != filename:
        raise AttributeError(
            f"Attempt to set monitoring filename to {filename} after it has already been set to {value}"
        )
    elif not rootService.isPropertySet(prop):
        rootService.MonitorFile = filename

    return ProvideRuntimeOptions(
        AllenBanksLocation=make_transposed_raw_banks(
            rawbank_list=rawbank_list))


def get_constants():
    from PyConf.application import make_odin
    return ProvideConstants(ODINLocation=make_odin())


def initialize_event_lists(**kwargs):
    name = kwargs.pop("name", "make_event_list_{hash}")
    initialize_lists = make_algorithm(
        host_init_event_list_t, name=name, **kwargs)
    return initialize_lists


# Gaudi configuration wrapper
def make_algorithm(algorithm, name, *args, **kwargs):

    # Deduce the types requested
    bank_type = kwargs.get('bank_type', '')
    rawbank_list = []
    if algorithm.type is odin_provider_t.type:
        rawbank_list = ["ODIN"]
    elif bank_type == "ECal":
        rawbank_list = ["Calo", "EcalPacked"]
    elif bank_type == "VP":
        rawbank_list = ["VP", "VPRetinaCluster"]
    elif bank_type:
        rawbank_list = [bank_type]

    rto = allen_runtime_options(rawbank_list)
    cs = get_constants()

    # Pass dev_event_list to inputs that are of type dev_event_list
    if algorithm is not host_init_event_list_t:
        dev_event_list = initialize_event_lists(
            name="make_event_list_{hash}",
            runtime_options_t=rto,
            constants_t=cs).dev_event_list_output_t
        event_list_names = [
            k for k, w in algorithm.getDefaultProperties().items()
            if isinstance(w, DataHandle) and dev_event_list.type == w.type()
            and w.mode() == "R"
        ]
        for dev_event_list_name in event_list_names:
            kwargs[dev_event_list_name] = dev_event_list

        return algorithm(
            name=name, runtime_options_t=rto, constants_t=cs, *args, **kwargs)
    else:
        return algorithm(name=name, runtime_options_t=rto, constants_t=cs)


# Empty generate to support importing Allen sequences in Gaudi-Allen
def generate(node):
    pass
