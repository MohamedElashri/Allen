###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.persistency import make_global_decision
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line

reconstructed_objects = hlt1_reconstruction(algorithm_name='calo_sequence')
ecal_clusters = reconstructed_objects["ecal_clusters"]

calo_digits_line = line_maker(
    make_calo_digits_minADC_line(
        decode_calo(), name="Hlt1CaloDigitsMinADC", minADC=100))

line_algorithms = [calo_digits_line[0]]

global_decision = make_global_decision(lines=line_algorithms)

lines = CompositeNode(
    "AllLines", [calo_digits_line[1]], NodeLogic.NONLAZY_OR, force_order=False)

calo_sequence = CompositeNode(
    "Calo", [lines, global_decision,
             rate_validation(lines=line_algorithms)],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(calo_sequence)
