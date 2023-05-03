###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.persistency import make_global_decision
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation
from AllenConf.hlt1_monitoring_lines import make_odin_event_type_line, make_odin_event_and_orbit_line
from AllenConf.plume_reconstruction import decode_plume
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.persistency import make_gather_selections
from AllenConf.lumi_reconstruction import lumi_reconstruction

lumiline_name = "Hlt1ODINLumi"
lumiline = line_maker(
    make_odin_event_type_line(name=lumiline_name, odin_event_type='Lumi'))
lumilinefull_name = "Hlt1ODIN1kHzLumi"
lumilinefull = line_maker(
    make_odin_event_and_orbit_line(
        name=lumilinefull_name,
        odin_event_type='Lumi',
        odin_orbit_modulo=30,
        odin_orbit_remainder=1))
line_algorithms = [lumiline[0], lumilinefull[0]]
gather_selections = make_gather_selections(lines=line_algorithms)

decoded_plume = decode_plume()
algos = [lumiline[1], lumilinefull[1], decoded_plume["plume_algo"]
         ] + lumi_reconstruction(
             gather_selections=gather_selections,
             lines=line_algorithms,
             lumiline_name=lumiline_name,
             lumilinefull_name=lumilinefull_name,
             with_muon=False,
             with_velo=False,
             with_SciFi=False,
             with_calo=False,
             with_plume=True)["algorithms"]

lumi_node = CompositeNode(
    "AllenLumiNode", algos, NodeLogic.NONLAZY_AND, force_order=False)

generate(lumi_node)
