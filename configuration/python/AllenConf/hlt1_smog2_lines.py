###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenAlgorithms.algorithms import SMOG2_minimum_bias_line_t, SMOG2_dimuon_highmass_line_t, SMOG2_ditrack_line_t, SMOG2_singletrack_line_t
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin


def make_SMOG2_dimuon_highmass_line(secondary_vertices,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None,
                                    name="Hlt1SMOG2_DiMuonHighMassLine"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_dimuon_highmass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_SMOG2_minimum_bias_line(velo_tracks,
                                 velo_states,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 name="Hlt1SMOG2_MinimumBias"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_minimum_bias_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_tracks_container_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"])


def make_SMOG2_ditrack_line(secondary_vertices,
                            m1=-1.,
                            m2=-1.,
                            mMother=-1.,
                            pre_scaler_hash_string=None,
                            post_scaler_hash_string=None,
                            name="Hlt1_SMOG2_DiTrack",
                            mWindow=150.,
                            minTrackP=3000.,
                            minTrackPt=400.):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_ditrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        m1=m1,
        m2=m2,
        mMother=mMother,
        massWindow=mWindow,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt)


def make_SMOG2_singletrack_line(long_tracks,
                                long_track_particles,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                name="Hlt1_SMOG2_SingleTrack"):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_singletrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
