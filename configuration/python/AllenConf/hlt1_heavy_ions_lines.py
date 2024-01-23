###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import heavy_ion_event_line_t, single_calo_cluster_line_t, two_calo_clusters_line_t
from AllenConf.velo_reconstruction import run_velo_kalman_filter
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable

# constants
__PbPb_SMOG_Z_SEPERATION = -341.


def make_photon_lowmult_line(calo,
                             name="Hlt1PhotonLowMult",
                             pre_scaler=1.,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             minEt=200.0,
                             max_ecal_clusters=999999):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_calo_cluster_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"],
        dev_particle_container_t=calo["dev_multi_event_neutral_particles"],
        minEt=minEt,
        max_ecal_clusters=max_ecal_clusters,
        enable_tupling=False)


def make_diphoton_lowmult_line(calo,
                               velo_tracks,
                               pvs,
                               name="Hlt1DiPhotonLowMult",
                               pre_scaler=1.,
                               post_scaler=1.,
                               pre_scaler_hash_string=None,
                               post_scaler_hash_string=None,
                               minMass=50,
                               maxPt=999999,
                               minEt_clusters=200,
                               max_velo_tracks=999999,
                               max_ecal_clusters=999999,
                               enable_monitoring=True,
                               mass_histogram_range=[0, 2000]):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_calo_clusters_line_t,
        name=name,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_velo_tracks_t=velo_tracks["dev_velo_tracks_view"],
        dev_particle_container_t=calo["dev_multi_event_diphotons"],
        dev_cluster_particle_container_t=calo[
            "dev_multi_event_neutral_particles"],
        host_number_of_svs_t=calo["host_ecal_number_of_twoclusters"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        minMass=minMass,  #MeV
        maxMass=999999,  #MeV
        maxPt=maxPt,  #MeV
        minEt_clusters=minEt_clusters,  #MeV
        minE19_clusters=0.4,
        max_velo_tracks=max_velo_tracks,
        max_ecal_clusters=max_ecal_clusters,
        enable_tupling=False,
        enable_monitoring=enable_monitoring,
        histogram_diphoton_mass_min=mass_histogram_range[0],
        histogram_diphoton_mass_max=mass_histogram_range[1])


@configurable
def make_heavy_ion_event_line(velo_tracks,
                              long_track_particles,
                              pvs,
                              decoded_calo,
                              pre_scaler_hash_string=None,
                              post_scaler_hash_string=None,
                              min_velo_tracks_PbPb=-1,
                              max_velo_tracks_PbPb=-1,
                              min_long_tracks=-1,
                              max_long_tracks=-1,
                              min_velo_tracks_SMOG=-1,
                              max_velo_tracks_SMOG=-1,
                              min_pvs_PbPb=-1,
                              max_pvs_PbPb=-1,
                              min_pvs_SMOG=-1,
                              max_pvs_SMOG=-1,
                              min_ecal_e=0.,
                              max_ecal_e=-1.,
                              PbPb_SMOG_z_separation=__PbPb_SMOG_Z_SEPERATION,
                              name="Hlt1HeavyIon_{hash}",
                              pre_scaler=1.):

    velo_states = run_velo_kalman_filter(velo_tracks)
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    return make_algorithm(
        heavy_ion_event_line_t,
        name=name,
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        dev_velo_tracks_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_t=velo_states["dev_velo_kalman_beamline_states_view"],
        dev_long_track_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_total_ecal_e_t=decoded_calo["dev_total_ecal_e"],
        dev_pvs_t=pvs["dev_multi_final_vertices"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        min_velo_tracks_PbPb=min_velo_tracks_PbPb,
        max_velo_tracks_PbPb=max_velo_tracks_PbPb,
        min_long_tracks=min_long_tracks,
        max_long_tracks=max_long_tracks,
        min_velo_tracks_SMOG=min_velo_tracks_SMOG,
        max_velo_tracks_SMOG=max_velo_tracks_SMOG,
        min_pvs_PbPb=min_pvs_PbPb,
        max_pvs_PbPb=max_pvs_PbPb,
        min_pvs_SMOG=min_pvs_SMOG,
        max_pvs_SMOG=max_pvs_SMOG,
        min_ecal_e=min_ecal_e,
        max_ecal_e=max_ecal_e,
        PbPb_SMOG_z_separation=PbPb_SMOG_z_separation,
        pre_scaler=pre_scaler)
