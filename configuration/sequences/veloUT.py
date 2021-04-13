###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.utils import gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.event_list_utils import generate


def ut_tracking():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    alg = ut_tracks["dev_ut_track_hits"].producer
    return alg


ut_tracking_sequence = CompositeNode(
    "UTTrackingWithGEC", [gec("gec"), ut_tracking()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(ut_tracking_sequence)
