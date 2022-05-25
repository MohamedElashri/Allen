from AllenConf.HLT1_PbPb import setup_hlt1_node
from AllenCore.generator import generate

hlt1_node = setup_hlt1_node()
generate(hlt1_node)