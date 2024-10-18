###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
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
from AllenConf.persistency import make_persistency
from AllenConf.filters import make_gec
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line, make_velo_micro_bias_line
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.odin import odin_error_filter, tae_filter, make_event_type, make_odin_orbit
from AllenConf.lumi_reconstruction import lumi_reconstruction

reconstructed_objects = hlt1_reconstruction()
ecal_clusters = reconstructed_objects["ecal_clusters"]

lines = []
lumiline_name = "Hlt1ODINLumi"
lumilinefull_name = "Hlt1ODIN1kHzLumi"

prefilters = [odin_error_filter("odin_error_filter")]
with line_maker.bind(prefilter=prefilters):
    lines.append(
        line_maker(
            make_single_calo_cluster_line(
                ecal_clusters,
                name="Hlt1SingleCaloCluster",
                minEt=400,
                pre_scaler=0.10)))
    lines.append(line_maker(make_passthrough_line(pre_scaler=0.04)))

odin_lumi_event = make_event_type(event_type='Lumi')
with line_maker.bind(prefilter=prefilters + [odin_lumi_event]):
    lines += [
        line_maker(make_passthrough_line(name=lumiline_name, pre_scaler=1.))
    ]

odin_orbit = make_odin_orbit(odin_orbit_modulo=30, odin_orbit_remainder=1)
with line_maker.bind(prefilter=prefilters + [odin_lumi_event, odin_orbit]):
    lines += [
        line_maker(
            make_passthrough_line(name=lumilinefull_name, pre_scaler=1.))
    ]

with line_maker.bind(prefilter=prefilters + [tae_filter()]):
    lines.append(
        line_maker(
            make_passthrough_line(name="Hlt1TAEPassthrough", pre_scaler=1)))

line_algorithms = [tup[0] for tup in lines]

lines = CompositeNode(
    "AllLines", [tup[1] for tup in lines],
    NodeLogic.NONLAZY_OR,
    force_order=False)

persistency_node, persistency_algorithms = make_persistency(line_algorithms)

calo_sequence = CompositeNode(
    "CaloClustering",
    [lines, persistency_node,
     rate_validation(lines=line_algorithms)],
    NodeLogic.NONLAZY_AND,
    force_order=True)

gather_selections = persistency_algorithms['gather_selections']

lumi_node = CompositeNode(
    "AllenLumiNode",
    lumi_reconstruction(
        gather_selections=gather_selections,
        lumiline_name=lumiline_name,
        lumilinefull_name=lumilinefull_name,
        with_muon=False,
        with_plume=True)["algorithms"],
    NodeLogic.NONLAZY_AND,
    force_order=False)

lumi_with_prefilter = CompositeNode(
    "LumiWithPrefilter",
    prefilters + [lumi_node],
    NodeLogic.LAZY_AND,
    force_order=True)

hlt1_node = CompositeNode(
    "AllenWithLumi", [calo_sequence, lumi_with_prefilter],
    NodeLogic.NONLAZY_AND,
    force_order=False)

generate(hlt1_node)
