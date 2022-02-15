###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (SMOG2_minimum_bias_line_t, SMOG2_dimuon_highmass_line_t, 
                                  SMOG2_ditrack_line_t, SMOG2_singletrack_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_SMOG2_minimum_bias_line(
        velo_tracks,
        velo_kalman_states,
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1SMOG2_MinimumBias"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        SMOG2_minimum_bias_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],        
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_velo_kalman_beamline_states_t=velo_kalman_states["dev_velo_kalman_beamline_states"] ,
        dev_velo_track_hit_number_t=velo_tracks["dev_offsets_velo_track_hit_number"] )


def make_SMOG2_dimon_highmass_line(
        secondary_vertices,
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1SMOG2_DiMuonHighMassLine"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        SMOG2_dimuon_highmass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_SMOG2_ditrack_line(
        secondary_vertices,
        m1="0.f",
        m2="0.f",
        mMother="0..f",
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1_SMOG2_DiTrack",
        mWindow="150.f",
        minTrackP="3000.f",
        minTrackPt="400.f"):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        SMOG2_ditrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        m1=m1,
        m2=m2,
        mMother=mMother,
        massWindow=mWindow,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt)


def make_SMOG2_singletrack_line(
        forward_tracks,
        kalman_velo_only,
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1_SMOG2_SingleTrack"):

    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        SMOG2_singletrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_track_offsets_t=forward_tracks["dev_offsets_forward_tracks"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
