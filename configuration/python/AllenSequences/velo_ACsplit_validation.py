###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, make_velo_tracks_ACsplit
#from AllenConf.primary_vertex_ACsplit_reconstruction import make_velo_tracks_ACsplit
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.validators import velo_validation, pv_validation
from AllenConf.primary_vertex_reconstruction import make_pvs

decoded_velo = decode_velo()

velo_tracks = make_velo_tracks(decoded_velo)
velo_tracks_A_side, velo_tracks_C_side = make_velo_tracks_ACsplit(decoded_velo)
pvs_A_side = make_pvs(velo_tracks_A_side, pv_name="_pv_A_side")
pvs_C_side = make_pvs(velo_tracks_C_side, pv_name="_pv_C_side")

velo_tracking_sequence = CompositeNode(
    "VeloTracking_A_side",
    [velo_validation(velo_tracks_A_side, name="velo_validator_A_side")],
    NodeLogic.NONLAZY_AND,
    force_order=True)

velo_tracking_sequence = CompositeNode(
    "VeloTracking_C_side", [
        velo_tracking_sequence,
        velo_validation(velo_tracks_C_side, name="velo_validator_C_side")
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

velo_tracking_sequence = CompositeNode(
    "pv_validation_A_side", [
        velo_tracking_sequence,
        pv_validation(pvs_A_side, name="pv_validator_A_side")
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

velo_tracking_sequence = CompositeNode(
    "pv_validation_C_side", [
        velo_tracking_sequence,
        pv_validation(pvs_C_side, name="pv_validator_C_side")
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(velo_tracking_sequence)
