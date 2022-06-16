###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import single_calo_cluster_line_t
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm


def make_single_calo_cluster_line(calo,
                                  name="Hlt1SingleCaloCluster",
                                  pre_scaler_hash_string=None,
                                  post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_calo_cluster_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_ecal_clusters_t=calo["dev_ecal_clusters"],
        dev_ecal_cluster_offsets_t=calo["dev_ecal_cluster_offsets"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"])
