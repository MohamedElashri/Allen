from AllenConf.HLT1_PbPb import setup_hlt1_node
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.generator import generate

with decode_velo.bind(retina_decoding=False):
    hlt1_node = setup_hlt1_node()
generate(hlt1_node)