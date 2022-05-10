from AllenConf.velo_reconstruction import velo_tracking, decode_velo
from AllenConf.calo_reconstruction import ecal_cluster_reco
from AllenConf.primary_vertex_reconstruction import pv_finder
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    node = CompositeNode(
        "PbPbRecoNoGEC", [pv_finder(), ecal_cluster_reco()],
        NodeLogic.NONLAZY_OR,
        force_order=True)

generate(node)