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
from PyConf.application import default_raw_banks
from PyConf.Algorithms import (ProvideConstants, TransposeRawBanks,
                               ProvideRuntimeOptions)
from GaudiKernel.DataHandle import DataHandle
from PyConf import configurable
from functools import cache


# Get the LHCb::RawBank::BankTypes that correspond to and HLT1/Allen
# subdetectors
@cache
def lhcb_bank_types(allen_sd):
    from Allen.bank_mapping import mapping
    lhcb_bts = set()
    for lhcb_bt, allen_sds in mapping.items():
        if allen_sd in allen_sds:
            lhcb_bts.add(lhcb_bt)
    return lhcb_bts


# Additional algorithms required by every Gaudi-Allen sequence
@configurable
def make_transposed_raw_banks(subdetector, make_raw_banks=default_raw_banks):
    bank_types = lhcb_bank_types(subdetector)

    return TransposeRawBanks(
        RawBankLocations=[make_raw_banks(k) for k in bank_types],
        BankTypes=[subdetector]
        if subdetector is not None else []).AllenRawInput


@configurable
def allen_runtime_options(subdetector, filename="allen_monitor.root"):
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
        AllenBanksLocation=make_transposed_raw_banks(subdetector=subdetector))


def get_constants():
    from PyConf.application import make_odin
    return ProvideConstants(ODINLocation=make_odin())


def initialize_event_lists(**kwargs):
    from PyConf.Algorithms import host_init_event_list_t
    name = kwargs.pop("name", "make_event_list_{hash}")
    initialize_lists = make_algorithm(
        host_init_event_list_t, name=name, **kwargs)
    return initialize_lists


# Gaudi configuration wrapper
def make_algorithm(algorithm, name, *args, **kwargs):
    from PyConf.application import make_odin
    from PyConf.Algorithms import odin_provider_t, host_init_event_list_t

    # Only ODIN has a dedicated provider that doesn't have the
    # `bank_type` property
    if algorithm.type is odin_provider_t.type:
        subdetector = "ODIN"
    else:
        subdetector = kwargs.get('bank_type', None)

    rto = allen_runtime_options(subdetector)
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
            name=name,
            ODIN=make_odin(),
            runtime_options_t=rto,
            constants_t=cs,
            *args,
            **kwargs)
    else:
        return algorithm(
            name=name, ODIN=make_odin(), runtime_options_t=rto, constants_t=cs)


# Empty generate to support importing Allen sequences in Gaudi-Allen
def generate(node):
    pass
