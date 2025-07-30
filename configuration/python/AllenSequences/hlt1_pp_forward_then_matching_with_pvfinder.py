from AllenConf.HLT1_with_pvfinder import setup_hlt1_node_with_pvfinder
from AllenCore.generator import generate
from AllenConf.enum_types import TrackingType

hlt1_node = setup_hlt1_node_with_pvfinder(tracking_type=TrackingType.FORWARD_THEN_MATCHING)
generate(hlt1_node['control_flow_node'])