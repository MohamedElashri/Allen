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
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_reconstruction import hlt1_reconstruction
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line


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
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()
    ecal_clusters = reconstructed_objects["ecal_clusters"]

    cosmics_lines = calo_cosmics_lines(ecal_clusters)

    # List of line algorithms,
    #   required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in cosmics_lines]
    # List of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in cosmics_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections_node = CompositeNode(
        "RunAllLines",
        [lines, make_gather_selections(lines=line_algorithms)],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_node = CompositeNode(
        "Cosmics",
        [gather_selections_node,
         make_global_decision(lines=line_algorithms)],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if enableRateValidator:
        hlt1_node = CompositeNode(
            "CosmicsRateValidation", [
                hlt1_node,
                rate_validation(lines=line_algorithms),
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)

    return hlt1_node
