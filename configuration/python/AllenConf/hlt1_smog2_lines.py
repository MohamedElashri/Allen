###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    SMOG2_minimum_bias_line_t, SMOG2_dimuon_highmass_line_t,
    SMOG2_ditrack_line_t, SMOG2_singletrack_line_t, SMOG2_single_muon_line_t,
    SMOG2_kstopipi_line_t)

from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


@configurable
def make_SMOG2_dimuon_highmass_line(secondary_vertices,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None,
                                    name="Hlt1SMOG2_DiMuonHighMassLine",
                                    min_z=-541,
                                    max_z=-341,
                                    pre_scaler=1.,
                                    post_scaler=1.,
                                    enable_monitoring=True,
                                    histogram_smogdimuon_mass_min=2700.,
                                    histogram_smogdimuon_mass_max=4000.,
                                    histogram_smogdimuon_mass_nbins=300,
                                    histogram_smogdimuon_svz_min=-541.,
                                    histogram_smogdimuon_svz_max=-341.,
                                    histogram_smogdimuon_svz_nbins=100):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_dimuon_highmass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minZ=min_z,
        maxZ=max_z,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        histogram_smogdimuon_mass_min=histogram_smogdimuon_mass_min,
        histogram_smogdimuon_mass_max=histogram_smogdimuon_mass_max,
        histogram_smogdimuon_mass_nbins=histogram_smogdimuon_mass_nbins,
        histogram_smogdimuon_svz_min=histogram_smogdimuon_svz_min,
        histogram_smogdimuon_svz_max=histogram_smogdimuon_svz_max,
        histogram_smogdimuon_svz_nbins=histogram_smogdimuon_svz_nbins)


@configurable
def make_SMOG2_minimum_bias_line(velo_tracks,
                                 velo_states,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 name="Hlt1SMOG2_MinimumBias",
                                 min_z=-541.,
                                 max_z=-341.,
                                 pre_scaler=1.,
                                 post_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_minimum_bias_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_tracks_container_t=velo_tracks["dev_velo_tracks_view"],
        dev_velo_states_view_t=velo_states[
            "dev_velo_kalman_beamline_states_view"],
        minZ=min_z,
        maxZ=max_z)


def make_SMOG2_ditrack_line(secondary_vertices,
                            m1=-1.,
                            m2=-1.,
                            mMother=-1.,
                            pre_scaler_hash_string=None,
                            post_scaler_hash_string=None,
                            name="Hlt1_SMOG2_DiTrack",
                            mWindow=150.,
                            minTrackP=3000.,
                            minTrackPt=400.,
                            min_z=-541.,
                            max_z=-341.,
                            pre_scaler=1.,
                            post_scaler=1.):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_ditrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        m1=m1,
        m2=m2,
        mMother=mMother,
        massWindow=mWindow,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt,
        minZ=min_z,
        maxZ=max_z)


def make_SMOG2_kstopipi_line(secondary_vertices,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             name="Hlt1_SMOG2_KsPiPi",
                             min_z=-541.,
                             max_z=-341.,
                             pre_scaler=1.,
                             post_scaler=1.,
                             enable_monitoring=True):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_kstopipi_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minPVZ=min_z,
        maxPVZ=max_z,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        histogram_smogks_svz_min=min_z)


def make_SMOG2_singletrack_line(long_tracks,
                                long_track_particles,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                name="Hlt1_SMOG2_SingleTrack",
                                min_z=-541.,
                                max_z=-341.,
                                pre_scaler=1.,
                                post_scaler=1.):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_singletrack_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minBPVz=min_z,
        maxBPVz=max_z)


def make_SMOG2_single_muon_line(long_tracks,
                                long_track_particles,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                name="Hlt1_SMOG2_SingleTrack",
                                min_z=-541.,
                                max_z=-341.,
                                pre_scaler=1.,
                                post_scaler=1.):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_single_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        minBPVz=min_z,
        maxBPVz=max_z)
