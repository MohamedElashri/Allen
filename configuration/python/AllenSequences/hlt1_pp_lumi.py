###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import odin_event_type_line_t, host_dummy_odin_provider_t

import AllenConf.hlt1_monitoring_lines

from AllenConf.utils import initialize_number_of_events
from AllenConf.odin import decode_odin
from AllenCore.generator import make_algorithm


def make_dummy_odin_event_type_line(odin_event_type: str,
                                    name=None,
                                    pre_scaler=1.,
                                    post_scaler=1.,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None):
    type_map = {
        "VeloOpen": 0x0001,
        "Physics": 0x0002,
        "NoBias": 0x0004,
        "Lumi": 0x0008,
        "Beam1Gas": 0x0010,
        "Beam2Gas": 0x0020
    }

    # fractions according to bunch crossing type
    lumi_fraction = [0.5, 0.5, 0.5, 0.5]

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    dummy_odin_lumi_throughput = make_algorithm(
        host_dummy_odin_provider_t,
        name="dummy_odin_lumi_throughput",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_odin_data_t=odin["host_odin_data"],
        lumi_frac=lumi_fraction)

    line_name = name or 'Hlt1ODIN' + odin_event_type
    return make_algorithm(
        odin_event_type_line_t,
        name=line_name,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        dev_odin_data_t=dummy_odin_lumi_throughput.dev_odin_dummy_t,
        odin_event_type=type_map[odin_event_type],
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or line_name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or line_name + "_post")


AllenConf.hlt1_monitoring_lines.make_odin_event_type_line = make_dummy_odin_event_type_line

import AllenConf.HLT1
from AllenCore.generator import generate

hlt1_node = AllenConf.HLT1.setup_hlt1_node()
generate(hlt1_node)
