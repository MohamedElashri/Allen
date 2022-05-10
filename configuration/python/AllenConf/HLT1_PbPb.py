###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import initialize_number_of_events, mep_layout, gec
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_calibration_lines import make_passthrough_line, make_rich_1_line, make_rich_2_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line, make_beam_gas_line

from AllenConf.validators import rate_validation
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin
from AllenConf.persistency import make_gather_selections, make_global_decision, make_sel_report_writer


# Helper function to make composite nodes with the gec
def make_line_composite_node_with_gec(line_name,
                                      line_algorithm,
                                      gec_name="gec"):
    return CompositeNode(
        line_name, [gec(name=gec_name), line_algorithm],
        NodeLogic.LAZY_AND,
        force_order=True)


@configurable
def line_maker(line_name, line_algorithm, enableGEC=True):
    if (enableGEC):
        node = make_line_composite_node_with_gec(line_name, line_algorithm)
    else:
        node = line_algorithm
    return line_algorithm, node

def default_lines(velo_tracks, forward_tracks, long_track_particles,
                  velo_states, calo):
    lines = []
    lines.append(
        line_maker(
            "Hlt1NoBeam",
            make_beam_line(
                beam_crossing_type=0,
                pre_scaler_hash_string="no_beam_line_pre",
                post_scaler_hash_string="no_beam_line_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1BeamOne",
            make_beam_line(
                beam_crossing_type=1,
                pre_scaler_hash_string="beam_one_line_pre",
                post_scaler_hash_string="beam_one_line_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1BeamTwo",
            make_beam_line(
                beam_crossing_type=2,
                pre_scaler_hash_string="beam_two_line_pre",
                post_scaler_hash_string="beam_two_line_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1BothBeams",
            make_beam_line(
                beam_crossing_type=3,
                pre_scaler_hash_string="both_beams_line_pre",
                post_scaler_hash_string="both_beams_line_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1VeloMicroBias",
            make_velo_micro_bias_line(velo_tracks),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1ODINLumi",
            make_odin_event_type_line(
                odin_event_type=0x8,
                pre_scaler_hash_string="odin_lumi_line_pre",
                post_scaler_hash_string="odin_lumi_line_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1ODINNoBias",
            make_odin_event_type_line(
                odin_event_type=0x4,
                pre_scaler_hash_string="odin_no_bias_pre",
                post_scaler_hash_string="odin_no_bias_post"),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1Passthrough", make_passthrough_line(), enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1RICH1Alignment",
            make_rich_1_line(forward_tracks, long_track_particles),
            enableGEC=True))
    lines.append(
        line_maker(
            "HLt1RICH2Alignment",
            make_rich_2_line(forward_tracks, long_track_particles),
            enableGEC=True))
    lines.append(
        line_maker(
            "Hlt1BeamGas",
            make_beam_gas_line(
                velo_tracks,
                velo_states,
                pre_scaler_hash_string="no_beam_line_pre",
                post_scaler_hash_string="no_beam_line_post",
                beam_crossing_type=1),
            enableGEC=True))
    lines.append(
        line_maker(
            "Hlt1GECPassthrough",
            make_passthrough_line(
                name="Hlt1GECPassthrough",
                pre_scaler_hash_string="passthrough_with_gec_line_pre",
                post_scaler_hash_string="passthrough_with_gec_line_post")))

    lines.append(
        line_maker(
            "Hlt1SinglePhoton",
            make_single_calo_cluster_line(calo),
            enableGEC=False))

    return lines


def setup_hlt1_node(withMCChecking=False, EnableGEC=True):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(add_electron_id=True)

    lines = default_lines(
        reconstructed_objects["velo_tracks"],
        reconstructed_objects["forward_tracks"],
        reconstructed_objects["long_track_particles"],
        reconstructed_objects["velo_states"],
        reconstructed_objects["ecal_clusters"])

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in lines]

    lines = CompositeNode(
        "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            make_global_decision(lines=line_algorithms),
            rate_validation(lines=line_algorithms),
            *make_sel_report_writer(
                lines=line_algorithms,
                forward_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"])
            ["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if not withMCChecking:
        return hlt1_node
    else:
        validation_node = validator_node(reconstructed_objects,
                                         line_algorithms)

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        return node
