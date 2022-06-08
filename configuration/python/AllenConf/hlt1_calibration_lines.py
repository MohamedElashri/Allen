###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import (
    d2kpi_line_t,
    passthrough_line_t,
    rich_1_line_t,
    rich_2_line_t,
    displaced_di_muon_mass_line_t,
    di_muon_mass_alignment_line_t,
)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_d2kpi_line(forward_tracks,
                    secondary_vertices,
                    name="Hlt1D2KPi",
                    pre_scaler_hash_string=None,
                    post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2kpi_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_passthrough_line(name="Hlt1Passthrough",
                          pre_scaler=1.,
                          pre_scaler_hash_string=None,
                          post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        passthrough_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_rich_line(line_type,
                   forward_tracks,
                   long_track_particles,
                   name,
                   pre_scaler,
                   post_scaler,
                   pre_scaler_hash_string=None,
                   post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        line_type,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_rich_1_line(forward_tracks,
                     long_track_particles,
                     name="Hlt1RICH1Alignment",
                     pre_scaler=1.0,
                     post_scaler=1.0,
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None):
    return make_rich_line(rich_1_line_t, forward_tracks, long_track_particles,
                          name, pre_scaler, post_scaler,
                          pre_scaler_hash_string, post_scaler_hash_string)


def make_rich_2_line(forward_tracks,
                     long_track_particles,
                     name="Hlt1RICH2Alignment",
                     pre_scaler=1.0,
                     post_scaler=1.0,
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None):
    return make_rich_line(rich_2_line_t, forward_tracks, long_track_particles,
                          name, pre_scaler, post_scaler,
                          pre_scaler_hash_string, post_scaler_hash_string)



def make_displaced_dimuon_mass_line(forward_tracks,
                                    secondary_vertices,
                                    name="Hlt1DisplacedDiMuonAlignment",
                                    pre_scaler=1.0,
                                    post_scaler=1.0,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        displaced_di_muon_mass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_di_muon_mass_align_line(forward_tracks,
                                 secondary_vertices,
                                 pre_scaler=1.0,
                                 post_scaler=1.0,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 minHighMassTrackPt=300.,
                                 minHighMassTrackP=6000.,
                                 maxDoca=0.2,
                                 maxVertexChi2=25.,
                                 minIPChi2=0.,
                                 name="Hlt1DiMuonHighMassAlignment"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_alignment_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minIPChi2=minIPChi2)
