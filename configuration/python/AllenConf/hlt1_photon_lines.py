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
from AllenCore.algorithms import single_calo_cluster_line_t, two_calo_clusters_line_t
from AllenConf.utils import initialize_number_of_events
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
        host_ecal_number_of_clusters_t=calo[
            "host_ecal_number_of_neutral_particles"],
        dev_particle_container_t=calo["dev_multi_event_neutral_particles"],
        minEt=minEt,
        maxEt=maxEt,
        enable_tupling=False)


def make_diphotonhighmass_line(calo,
                               velo_tracks,
                               pvs,
                               name="Hlt1DiPhotonHighMass",
                               pre_scaler=1.,
                               post_scaler=1.,
                               pre_scaler_hash_string=None,
                               post_scaler_hash_string=None,
                               enable_tupling=False,
                               minET=6000):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_calo_clusters_line_t,
        name=name,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_t=velo_tracks["dev_velo_tracks_view"],
        dev_particle_container_t=calo["dev_multi_event_diphotons"],
        dev_cluster_particle_container_t=calo[
            "dev_multi_event_neutral_particles"],
        host_number_of_svs_t=calo["host_ecal_number_of_twoclusters"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        minMass=4200,  #MeV
        maxMass=21000,  #MeV
        minPt=3000,
        minEt_clusters=minET,
        minSumEt_clusters=6000,
        minE19_clusters=0.6,
        maxE19_clusters=1.0,
        enable_tupling=enable_tupling)
