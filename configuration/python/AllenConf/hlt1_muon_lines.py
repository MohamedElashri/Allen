###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (
    single_high_pt_muon_line_t, single_high_pt_muon_no_muid_line_t,
    low_pt_muon_line_t, di_muon_mass_line_t, di_muon_soft_line_t,
    low_pt_di_muon_line_t, track_muon_mva_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_single_high_pt_muon_line(
        forward_tracks,
        long_track_particles,
        pre_scaler_hash_string="single_high_pt_muon_line_pre",
        post_scaler_hash_string="single_high_pt_muon_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        single_high_pt_muon_line_t,
        name="Hlt1SingleHighPtMuon",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_single_high_pt_muon_no_muid_line(
        forward_tracks,
        long_track_particles,
        pre_scaler_hash_string="single_high_pt_muon_no_muid_line_pre",
        post_scaler_hash_string="single_high_pt_muon_no_muid_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        single_high_pt_muon_no_muid_line_t,
        name="Hlt1SingleHighPtMuonNoMuID",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_low_pt_muon_line(forward_tracks,
                          long_track_particles,
                          pre_scaler_hash_string="low_pt_muon_line_pre",
                          post_scaler_hash_string="low_pt_muon_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        low_pt_muon_line_t,
        name="Hlt1LowPtMuon",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


def make_di_muon_mass_line(forward_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string="di_muon_mass_line_pre",
                           post_scaler_hash_string="di_muon_mass_line_post",
                           minHighMassTrackPt=300.,
                           minHighMassTrackP=6000.,
                           minMass=2700.,
                           maxDoca=0.2,
                           maxVertexChi2=25.,
                           minIPChi2=0.,
                           name="Hlt1DiMuonHighMass"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        di_muon_mass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        minMass=minMass,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minIPChi2=minIPChi2)


def make_di_muon_soft_line(forward_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string="di_muon_soft_line_pre",
                           post_scaler_hash_string="di_muon_soft_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        di_muon_soft_line_t,
        name="Hlt1DiMuonSoft",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_low_pt_di_muon_line(
        forward_tracks,
        secondary_vertices,
        pre_scaler_hash_string="low_pt_di_muon_line_pre",
        post_scaler_hash_string="low_pt_di_muon_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        low_pt_di_muon_line_t,
        name="Hlt1LowPtDiMuon",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)


def make_track_muon_mva_line(
        forward_tracks,
        long_track_particles,
        pre_scaler_hash_string="track_muon_mva_line_pre",
        post_scaler_hash_string="track_muon_mva_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        track_muon_mva_line_t,
        name="Hlt1TrackMuonMVA",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)
