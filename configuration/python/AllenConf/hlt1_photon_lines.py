###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import single_calo_cluster_line_t, two_calo_clusters_line_t
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm


def make_single_calo_cluster_line(calo,
                                  name="Hlt1SingleCaloCluster",
                                  pre_scaler=1.,
                                  pre_scaler_hash_string=None,
                                  post_scaler_hash_string=None,
                                  minEt=200.0,
                                  maxEt=10000.0):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_calo_cluster_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_ecal_clusters_t=calo["dev_ecal_clusters"],
        dev_ecal_cluster_offsets_t=calo["dev_ecal_cluster_offsets"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"],
        minEt=minEt,
        maxEt=maxEt,
        enable_monitoring=False)


def make_bs2gammagamma_line(calo,
                            pvs,
                            name="Hlt1Bs2GammaGamma",
                            pre_scaler_hash_string=None,
                            post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()
    layout = mep_layout()

    return make_algorithm(
        two_calo_clusters_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_ecal_twoclusters_t=calo["dev_ecal_twoclusters"],
        dev_ecal_twocluster_offsets_t=calo["dev_ecal_twocluster_offsets"],
        host_ecal_number_of_twoclusters_t=calo[
            "host_ecal_number_of_twoclusters"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        minMass=3000,  #MeV
        maxMass=8000,  #MeV
        minEt=1000,
        minEt_clusters=2500,
        minSumEt_clusters=0,
        minE19_clusters=0.6,
        enable_monitoring=False)
