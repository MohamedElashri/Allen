###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import make_velo_tracks, decode_velo, run_velo_kalman_filter, filter_tracks_for_material_interactions
from AllenConf.hlt1_monitoring_lines import make_n_displaced_velo_line, make_velo_micro_bias_line, make_n_materialvertex_seed_line
from AllenCore.generator import generate
from AllenConf.persistency import make_global_decision, make_routingbits_writer, make_sel_report_writer
from AllenConf.utils import line_maker
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.validators import rate_validation
from AllenConf.odin import odin_error_filter

odin_err_filter = odin_error_filter("odin_error_filter")
decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)
velo_states = run_velo_kalman_filter(velo_tracks)
filtered_tracks = filter_tracks_for_material_interactions(
    velo_tracks, velo_states, beam_r_distance=18.0, close_doca=0.5)

with line_maker.bind(prefilter=[odin_err_filter]):
    lines = [
        line_maker(make_velo_micro_bias_line(velo_tracks, post_scaler=0.01)),
        line_maker(make_n_displaced_velo_line(filtered_tracks, n_tracks=3)),
        line_maker(make_n_materialvertex_seed_line(filtered_tracks))
    ]

    line_algorithms = [tup[0] for tup in lines]
    line_node = CompositeNode(
        "SetupAllLines", [tup[1] for tup in lines],
        NodeLogic.NONLAZY_OR,
        force_order=False)

    velo_line_node = CompositeNode(
        "velo_line_node", [
            line_node,
            make_global_decision(lines=line_algorithms),
            make_routingbits_writer(lines=line_algorithms),
            *make_sel_report_writer(lines=line_algorithms)["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_node = CompositeNode(
        "velo_mapping", [
            velo_line_node,
            rate_validation(lines=line_algorithms),
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    generate(hlt1_node)
