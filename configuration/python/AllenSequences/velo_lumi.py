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
from AllenConf.utils import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import make_algorithm
from AllenCore.generator import generate
from AllenConf.odin import decode_odin
from AllenConf.utils import initialize_number_of_events

from AllenCore.algorithms import odin_event_type_line_t, host_dummy_odin_provider_t
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line, make_odin_event_type_line, make_odin_event_and_orbit_line, make_velo_micro_bias_line
from AllenConf.persistency import make_global_decision, make_gather_selections, make_routingbits_writer
from AllenConf.utils import line_maker, make_gec
from AllenConf.odin import odin_error_filter


# dummy line with simulated lumi event type
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


decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)

lines = []
lumiline_name = "Hlt1ODINLumi"
lumilinefull_name = "Hlt1ODIN1kHzLumi"

prefilters = [odin_error_filter("odin_error_filter")]
with line_maker.bind(prefilter=prefilters):
    lines.append(
        line_maker(
            make_dummy_odin_event_type_line(
                name=lumiline_name, odin_event_type='Lumi')))
    lines.append(
        line_maker(
            make_odin_event_and_orbit_line(
                name=lumilinefull_name,
                odin_event_type='Lumi',
                odin_orbit_modulo=30,
                odin_orbit_remainder=1)))

line_algorithms = [tup[0] for tup in lines]

lines = CompositeNode(
    "AllLines", [tup[1] for tup in lines],
    NodeLogic.NONLAZY_OR,
    force_order=False)

gather_selections = make_gather_selections(lines=line_algorithms)

lumi_node = CompositeNode(
    "AllenLumiNode", [lines] + lumi_reconstruction(
        gather_selections=gather_selections,
        lines=line_algorithms,
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
