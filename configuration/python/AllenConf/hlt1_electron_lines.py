###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (
    track_electron_mva_line_t, single_high_pt_electron_line_t,
    displaced_dielectron_line_t, displaced_leptons_line_t,
    single_high_et_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_track_electron_mva_line(
        forward_tracks,
        long_track_particles,
        calo,
        pre_scaler_hash_string="track_electron_mva_line_pre",
        post_scaler_hash_string="track_electron_mva_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        track_electron_mva_line_t,
        name="Hlt1TrackElectronMVA",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_single_high_pt_electron_line(
        forward_tracks,
        long_track_particles,
        calo,
        pre_scaler_hash_string="single_high_pt_electron_line_pre",
        post_scaler_hash_string="single_high_pt_electron_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        single_high_pt_electron_line_t,
        name="Hlt1SingleHighPtElectron",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_displaced_dielectron_line(
        forward_tracks,
        secondary_vertices,
        calo,
        pre_scaler_hash_string="displaced_dielectron_line_pre",
        post_scaler_hash_string="displaced_dielectron_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        displaced_dielectron_line_t,
        name="Hlt1DisplacedDielectron",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        dev_track_offsets_t=forward_tracks["dev_offsets_forward_tracks"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_displaced_leptons_line(
        forward_tracks,
        long_track_particles,
        calo,
        pre_scaler_hash_string="displaced_leptons_line_pre",
        post_scaler_hash_string="displaced_leptons_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        displaced_leptons_line_t,
        name="Hlt1DisplacedLeptons",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_single_high_et_line(
        velo_tracks,
        calo,
        pre_scaler_hash_string="single_high_et_line_pre",
        post_scaler_hash_string="single_high_et_line_post"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        single_high_et_line_t,
        name="Hlt1SingleHighEt",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        dev_velo_tracks_offsets_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_brem_ET_t=calo["dev_brem_ET"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)
