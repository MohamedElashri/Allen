###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import (
    single_high_pt_muon_line_t, single_high_pt_muon_no_muid_line_t,
    low_pt_muon_line_t, di_muon_mass_line_t, di_muon_soft_line_t,
    low_pt_di_muon_line_t, track_muon_mva_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm


def make_single_high_pt_muon_line(forward_tracks,
                                  long_track_particles,
                                  name="Hlt1SingleHighPtMuon",
                                  pre_scaler_hash_string=None,
                                  post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_pt_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_single_high_pt_muon_no_muid_line(forward_tracks,
                                          long_track_particles,
                                          name="Hlt1SingleHighPtMuonNoMuID",
                                          pre_scaler_hash_string=None,
                                          post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_pt_muon_no_muid_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_low_pt_muon_line(forward_tracks,
                          long_track_particles,
                          name="Hlt1LowPtMuon",
                          pre_scaler_hash_string=None,
                          post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        low_pt_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_di_muon_mass_line(forward_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           minHighMassTrackPt=300.,
                           minHighMassTrackP=6000.,
                           minMass=2700.,
                           maxDoca=0.2,
                           maxVertexChi2=25.,
                           minIPChi2=0.,
                           name="Hlt1DiMuonHighMass"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        minMass=minMass,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minIPChi2=minIPChi2)


def make_di_muon_soft_line(forward_tracks,
                           secondary_vertices,
                           name="Hlt1DiMuonSoft",
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_soft_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_low_pt_di_muon_line(forward_tracks,
                             secondary_vertices,
                             name="Hlt1LowPtDiMuon",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        low_pt_di_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_track_muon_mva_line(forward_tracks,
                             long_track_particles,
                             name="Hlt1TrackMuonMVA",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        track_muon_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
