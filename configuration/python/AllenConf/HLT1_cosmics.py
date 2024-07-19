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
from AllenConf.persistency import make_persistency
from AllenConf.utils import line_maker
from AllenConf.filters import sd_error_filter
from AllenConf.validators import rate_validation
from AllenConf.hlt1_photon_lines import make_single_calo_cluster_line
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line, make_t_cosmic_line, make_velo_micro_bias_line
from AllenConf.hlt1_muon_lines import make_one_muon_track_line
from AllenConf.calo_reconstruction import decode_calo, make_ecal_clusters
from AllenConf.scifi_reconstruction import decode_scifi, make_seeding_XZ_tracks, make_seeding_tracks
from AllenConf.muon_reconstruction import make_muon_stubs
from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
from AllenConf.hlt1_calibration_lines import make_passthrough_line


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


def scifi_cosmics_lines(seed_tracks):
    lines = []

    lines.append(
        line_maker(make_t_cosmic_line(seed_tracks, name="Hlt1TCosmic")))

    return lines


def muon_cosmic_lines(muon_stubs):
    lines = [
        line_maker(
            make_one_muon_track_line(
                muon_stubs["consolidated_muon_tracks"],
                muon_stubs["dev_muon_tracks_offsets"],
                muon_stubs["host_muon_total_number_of_tracks"],
                name="Hlt1OneMuonStub"))
    ]
    return lines


def alignment_monitoring_lines(velo_tracks):
    lines = [
        line_maker(
            make_velo_micro_bias_line(velo_tracks, name="Hlt1VeloMicroBias"))
    ]

    with line_maker.bind(prefilter=[sd_error_filter()]):
        lines += [
            line_maker(
                make_passthrough_line(name="Hlt1ErrorBank", pre_scaler=0.01))
        ]

    return lines


def setup_hlt1_node(enableRateValidator=True):

    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    decoded_calo = decode_calo()
    ecal_clusters = make_ecal_clusters(
        decoded_calo, calo_find_clusters_name='calo_find_clusters_cosmics')

    hlt1_config['reconstruction'] = {'ecal_clusters': ecal_clusters}

    cosmics_lines = calo_cosmics_lines(ecal_clusters)

    decoded_scifi = decode_scifi()
    seeding_xz_tracks = make_seeding_XZ_tracks(decoded_scifi)
    seeding_tracks = make_seeding_tracks(
        decoded_scifi,
        seeding_xz_tracks,
        scifi_consolidate_seeds_name='seeding_sequence_scifi_consolidate_seeds'
    )

    scifi_lines = scifi_cosmics_lines(seeding_tracks)

    muon_stubs = make_muon_stubs(monitoring=False)
    muon_lines = muon_cosmic_lines(muon_stubs)

    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)

    monitoring_lines = alignment_monitoring_lines(velo_tracks)

    # List of line algorithms,
    #   required for the gather selection and DecReport algorithms
    line_algorithms = [
        tup[0]
        for tup in cosmics_lines + scifi_lines + muon_lines + monitoring_lines
    ]
    # List of line nodes, required to set up the CompositeNode
    line_nodes = [
        tup[1]
        for tup in cosmics_lines + scifi_lines + muon_lines + monitoring_lines
    ]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    persistency_node, persistency_algorithms = make_persistency(
        line_algorithms)

    hlt1_node = CompositeNode(
        "Cosmics", [lines, persistency_node],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config.update(persistency_algorithms)

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
