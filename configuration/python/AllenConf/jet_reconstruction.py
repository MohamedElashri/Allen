###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import build_cone_jets_t, make_neutral_particles_t
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_cone_jets(long_tracks,
                   long_track_particles,
                   ecal_clusters,
                   n_max_jets=8):
    number_of_events = initialize_number_of_events()

    build_cone_jets = make_algorithm(
        build_cone_jets_t,
        name='build_cone_jets_{hash}',
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        host_number_of_neutrals_t=ecal_clusters[
            "host_ecal_number_of_neutral_particles"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_long_track_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_neutral_particle_container_t=ecal_clusters[
            "dev_multi_event_neutral_particles"],
        n_max_jets=n_max_jets)

    make_jet_particles = make_algorithm(
        make_neutral_particles_t,
        name="make_neutral_particles_{hash}",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_neutral_clusters_t=build_cone_jets.
        host_number_of_jets_t,
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_ecal_cluster_offsets_t=build_cone_jets.dev_jet_offsets_t,
        dev_ecal_neutral_cluster_offsets_t=build_cone_jets.dev_jet_offsets_t,
        dev_ecal_clusters_t=build_cone_jets.dev_jet_clusters_t)

    return {
        "host_number_of_jets":
        build_cone_jets.host_number_of_jets_t,
        "dev_multi_event_jets":
        make_jet_particles.dev_multi_event_neutral_particles_view_t
    }
