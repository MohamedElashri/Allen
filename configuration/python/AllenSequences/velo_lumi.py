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
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, run_velo_kalman_filter
from AllenConf.filters import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import make_algorithm
from AllenCore.generator import generate
from AllenConf.utils import initialize_number_of_events, line_maker
from AllenCore.algorithms import host_dummy_odin_provider_t
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line, make_velo_micro_bias_line
from AllenConf.persistency import make_global_decision, make_gather_selections, make_routingbits_writer
from AllenConf.odin import odin_error_filter, make_event_type, decode_odin, make_odin_orbit
from AllenConf.hlt1_calibration_lines import make_passthrough_line
import AllenConf


def decode_dummy_odin(lumi_fraction=[0.5, 0.5, 0.5, 0.5]):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    dummy_odin_banks = make_algorithm(
        host_dummy_odin_provider_t,
        name="dummy_odin_lumi_throughput",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_odin_data_t=odin["host_odin_data"],
        lumi_frac=lumi_fraction)

    return {
        "dev_odin_data": dummy_odin_banks.dev_odin_dummy_t,
        "host_odin_data": dummy_odin_banks.host_odin_dummy_t,
        "host_odin_version": odin["host_odin_version"],
        "host_event_list": odin["host_event_list"],
        "dev_event_mask": odin["dev_event_mask"]
    }


AllenConf.odin.decode_odin = decode_dummy_odin
decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)

lines = []
lumiline_name = "Hlt1ODINLumi"
lumilinefull_name = "Hlt1ODIN1kHzLumi"

prefilters = [odin_error_filter("odin_error_filter")]
odin_lumi_event = make_event_type(event_type='Lumi')
with line_maker.bind(prefilter=prefilters + [odin_lumi_event]):
    lines += [
        line_maker(make_passthrough_line(name=lumiline_name, pre_scaler=1.))
    ]

odin_orbit = make_odin_orbit(odin_orbit_modulo=30, odin_orbit_remainder=1)
with line_maker.bind(prefilter=prefilters + [odin_lumi_event, odin_orbit]):
    lines += [
        line_maker(
            make_passthrough_line(name=lumilinefull_name, pre_scaler=1.))
    ]

line_algorithms = [tup[0] for tup in lines]

lines = CompositeNode(
    "AllLines", [tup[1] for tup in lines],
    NodeLogic.NONLAZY_OR,
    force_order=False)

gather_selections = make_gather_selections(lines=line_algorithms)

lumi_node = CompositeNode(
    "AllenLumiNode", [lines] + lumi_reconstruction(
        gather_selections=gather_selections,
        lumiline_name=lumiline_name,
        lumilinefull_name=lumilinefull_name,
        with_muon=False,
        with_velo=True,
        with_SciFi=False,
        with_calo=False,
        with_plume=False,
        velo_open=False,
    )["algorithms"],
    NodeLogic.NONLAZY_AND,
    force_order=False)

lumi_with_prefilter = CompositeNode(
    "LumiWithPrefilter",
    prefilters + [lumi_node],
    NodeLogic.LAZY_AND,
    force_order=True)

kalman_filter = velo_states['dev_velo_kalman_endvelo_states'].producer

node = CompositeNode(
    "VeloTrackingWithGEC", [make_gec("gec", count_ut=False), kalman_filter],
    NodeLogic.LAZY_AND,
    force_order=False)

# This is for import by the allen_gaudi_velo_with_mcchecking test
config = {
    'control_flow_node': node,
    'reconstruction': {
        'velo_tracks': velo_tracks,
        'velo_states': velo_states
    }
}

hlt1_node = CompositeNode(
    "AllenWithLumi", [lumi_with_prefilter, node],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(hlt1_node)
