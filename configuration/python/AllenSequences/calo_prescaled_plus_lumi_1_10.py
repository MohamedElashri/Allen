###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.persistency import make_global_decision, make_gather_selections, make_routingbits_writer
from AllenConf.utils import line_maker, make_gec
from AllenConf.validators import rate_validation
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line, make_odin_event_type_line, make_velo_micro_bias_line
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.odin import make_bxtype, odin_error_filter, tae_filter
from AllenConf.lumi_reconstruction import lumi_reconstruction

reconstructed_objects = hlt1_reconstruction()
ecal_clusters = reconstructed_objects["ecal_clusters"]

lines = []
lumiline_name = "Hlt1ODINLumi"

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
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name=lumiline_name, odin_event_type='Lumi')))

with line_maker.bind(prefilter=prefilters + [tae_filter()]):
    lines.append(
        line_maker(
            make_passthrough_line(name="Hlt1TAEPassthrough", pre_scaler=1)))

line_algorithms = [tup[0] for tup in lines]

global_decision = make_global_decision(lines=line_algorithms)

lines = CompositeNode(
    "AllLines", [tup[1] for tup in lines],
    NodeLogic.NONLAZY_OR,
    force_order=False)

calo_sequence = CompositeNode(
    "CaloClustering", [
        lines, global_decision,
        make_routingbits_writer(lines=line_algorithms),
        rate_validation(lines=line_algorithms)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

gather_selections = make_gather_selections(lines=line_algorithms)

lumi_node = CompositeNode(
    "AllenLumiNode",
    lumi_reconstruction(
        gather_selections=gather_selections,
        lines=line_algorithms,
        lumiline_name=lumiline_name,
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
