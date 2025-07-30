###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (odin_provider_t, odin_beamcrossingtype_t,
                                  odin_nzsfilter_t, host_odin_error_filter_t,
                                  host_tae_filter_t, odin_eventtype_t,
                                  odin_orbitnumber_t)
from AllenCore.generator import make_algorithm
from AllenConf.utils import mep_layout, initialize_number_of_events
from PyConf.tonic import configurable


def decode_odin():
    odin_banks = make_algorithm(
        odin_provider_t,
        name="populate_odin_banks",
        host_number_of_events_t=initialize_number_of_events()
        ['host_number_of_events'],
        host_mep_layout_t=mep_layout()['host_mep_layout'])

    return {
        "dev_odin_data": odin_banks.dev_odin_data_t,
        "host_odin_data": odin_banks.host_odin_data_t,
        "host_odin_version": odin_banks.host_raw_bank_version_t,
        "host_event_list": odin_banks.host_event_list_t,
        "dev_event_mask": odin_banks.dev_event_mask_t
    }


@configurable
def make_nzs_filter(name="ODIN_NonZSFilter", nzsfilter=True):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_nzsfilter_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'],
        nzs_bit=nzsfilter)


@configurable
def make_bxtype(name=None, bx_type=3, invert=False):
    if name is None:
        name = {
            0: "BX_EmptyEmpty",
            1: "BX_BeamEmpty",
            2: "BX_EmptyBeam",
            3: "BX_BeamBeam",
        }[bx_type]
    return ODIN_BeamXtype(name=name, bxtype=bx_type, invert=invert)


def ODIN_BeamXtype(name='ODIN_BeamXType', bxtype=3, invert=False):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_beamcrossingtype_t,
        name=name,
        invert=invert,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'],
        beam_crossing_type=bxtype)


@configurable
def make_event_type(name=None, event_type="VeloOpen", invert=False):

    type_map = {
        "VeloOpen": 0x0001,
        "Physics": 0x0002,
        "NoBias": 0x0004,
        "Lumi": 0x0008,
        "Beam1Gas": 0x0010,
        "Beam2Gas": 0x0020,
        "ee_far_from_activity": 0x8000
    }

    return ODIN_event_type(
        name=name or f"ODIN_EvenType_{event_type}",
        event_type=type_map[event_type],
        invert=invert)


def ODIN_event_type(name, event_type, invert):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_eventtype_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'],
        event_type=event_type,
        invert=invert)


def odin_error_filter(name="odin_error_filter"):
    odin_error_filter = make_algorithm(
        host_odin_error_filter_t,
        name="odin_error_filter",
        dev_event_mask_t=decode_odin()["dev_event_mask"])
    return odin_error_filter


@configurable
def tae_filter(name="tae_filter", accept_sub_events=False):
    odin = decode_odin()
    host_tae_filter = make_algorithm(
        host_tae_filter_t,
        name="tae_filter",
        host_event_list_t=odin["host_event_list"],
        host_number_of_events_t=initialize_number_of_events()
        ['host_number_of_events'],
        host_odin_data_t=odin["host_odin_data"],
        accept_sub_events=accept_sub_events)
    return host_tae_filter


@configurable
def make_odin_orbit(name=None, odin_orbit_modulo=30, odin_orbit_remainder=1):

    return ODIN_orbit_number(
        name=name or f"ODIN_Orbit_{odin_orbit_modulo}_{odin_orbit_remainder}",
        odin_orbit_modulo=odin_orbit_modulo,
        odin_orbit_remainder=odin_orbit_remainder)


def ODIN_orbit_number(name, odin_orbit_modulo, odin_orbit_remainder):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_orbitnumber_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'],
        odin_orbit_modulo=odin_orbit_modulo,
        odin_orbit_remainder=odin_orbit_remainder)
