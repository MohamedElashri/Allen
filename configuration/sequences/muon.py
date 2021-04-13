###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import gec
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks
from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks
from AllenConf.muon_reconstruction import decode_muon, is_muon
from AllenCore.event_list_utils import generate
from PyConf.control_flow import NodeLogic, CompositeNode


def muon_id():
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    forward_tracks = make_forward_tracks(decoded_scifi, ut_tracks)
    decoded_muon = decode_muon()
    muonID = is_muon(decoded_muon, forward_tracks)
    alg = muonID["dev_is_muon"].producer
    return alg


muon_id_sequence = CompositeNode(
    "MuonIDWithGEC", [gec("gec"), muon_id()],
    NodeLogic.LAZY_AND,
    force_order=True)

generate(muon_id_sequence)
