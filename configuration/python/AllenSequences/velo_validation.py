###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks, velo_tracking
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.validators import velo_validation

decoded_velo = decode_velo()
velo_tracks = make_velo_tracks(decoded_velo)

velo_tracking_sequence = CompositeNode(
    "VeloTrackingWithGEC",
    [gec("gec"), velo_validation(velo_tracks)],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(velo_tracking_sequence)
