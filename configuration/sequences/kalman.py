from AllenConf.utils import gec
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

kalman_sequence = CompositeNode(
    "KalmanSequence", [gec("gec"), hlt1_reconstruction()["secondary_vertices"]["dev_two_track_particles"].producer],
    NodeLogic.LAZY_AND,
    force_order=True)
generate(kalman_sequence)