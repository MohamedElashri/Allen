###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.persistency import make_global_decision
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation
from AllenConf.plume_reconstruction import decode_plume
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_gather_selections
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.odin import odin_error_filter, make_event_type, make_odin_orbit

lumiline_name = "Hlt1ODINLumi"
odin_lumi_event = make_event_type(event_type='Lumi')
with line_maker.bind(prefilter=odin_lumi_event):
    lumiline = line_maker(
        make_passthrough_line(name=lumiline_name, pre_scaler=1.))

lumilinefull_name = "Hlt1ODIN1kHzLumi"
odin_orbit = make_odin_orbit(odin_orbit_modulo=30, odin_orbit_remainder=1)
with line_maker.bind(prefilter=[odin_lumi_event, odin_orbit]):
    lumilinefull = line_maker(
        make_passthrough_line(name=lumilinefull_name, pre_scaler=1.))

line_algorithms = [lumiline[0], lumilinefull[0]]
gather_selections = make_gather_selections(lines=line_algorithms)

decoded_plume = decode_plume()
algos = [lumiline[1], lumilinefull[1], decoded_plume["plume_algo"]
         ] + lumi_reconstruction(
             gather_selections=gather_selections,
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
