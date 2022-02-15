###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import single_calo_cluster_line_t
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_single_calo_cluster_line(
        calo,
        name="Hlt1SingleCaloCluster",
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        single_calo_cluster_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_ecal_clusters_t=calo["dev_ecal_clusters"],
        dev_ecal_cluster_offsets_t=calo["dev_ecal_cluster_offsets"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"])
