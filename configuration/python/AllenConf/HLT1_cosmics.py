###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.persistency import make_gather_selections, make_global_decision
from AllenConf.HLT1 import line_maker
from AllenConf.validators import rate_validation
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line
from AllenConf.calo_reconstruction import decode_calo, make_ecal_clusters


def calo_cosmics_lines(ecal_clusters):
    lines = []
    lines.append(
        line_maker(
            make_single_calo_cluster_line(ecal_clusters,
                                          "Hlt1SingleCaloCluster")))
    lines.append(
        line_maker(
            make_calo_digits_minADC_line(
                decode_calo(), name="Hlt1CaloDigitsMinADC")))

    return lines


def setup_hlt1_node(enableRateValidator=True):

    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    decoded_calo = decode_calo()
    ecal_clusters = make_ecal_clusters(decoded_calo)

    hlt1_config['reconstruction'] = {'ecal_clusters': ecal_clusters}

    cosmics_lines = calo_cosmics_lines(ecal_clusters)

    # List of line algorithms,
    #   required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in cosmics_lines]
    # List of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in cosmics_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections = make_gather_selections(lines=line_algorithms)
    global_decision = make_global_decision(lines=line_algorithms)

    hlt1_config['gather_selections'] = gather_selections
    hlt1_config['global_decision'] = global_decision

    gather_selections_node = CompositeNode(
        "RunAllLines", [lines, gather_selections],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_node = CompositeNode(
        "Cosmics", [gather_selections_node, global_decision],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms

    if enableRateValidator:
        hlt1_node = CompositeNode(
            "CosmicsRateValidation", [
                hlt1_node,
                rate_validation(lines=line_algorithms),
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)

    hlt1_config['control_flow_node'] = hlt1_node
    return hlt1_config
