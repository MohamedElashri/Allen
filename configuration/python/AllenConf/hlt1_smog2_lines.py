###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (
    SMOG2_minimum_bias_line_t, SMOG2_dimuon_highmass_line_t,
    SMOG2_ditrack_line_t, SMOG2_singletrack_line_t, SMOG2_single_muon_line_t,
    SMOG2_kstopipi_line_t, SMOG2_displaced_di_muon_line_t,
    SMOG2jpsitomumu_tap_line_t)

from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenConf.odin import decode_odin
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


@configurable
def make_SMOG2_dimuon_displaced_line(secondary_vertices,
                                     long_tracks,
                                     muonid,
                                     pre_scaler_hash_string=None,
                                     post_scaler_hash_string=None,
                                     name="Hlt1SMOG2_DisplacedDiMuon",
                                     mintrackpt=500,
                                     maxvtxchi2=25,
                                     mincombopt=1.,
                                     min_PVz=-537.5,
                                     max_PVz=-337.5,
                                     minFDCHI2=15.,
                                     min_SVz=-537.5,
                                     maxIP=1.,
                                     maxChi2Corr=2.0,
                                     minMuonNN=0.05,
                                     useMuonNN=False,
                                     pre_scaler=1.,
                                     post_scaler=1.,
                                     enable_monitoring=True):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_displaced_di_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        dev_muonidnn_t=muonid["dev_muonidnn"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minDispTrackPt=mintrackpt,
        maxVertexChi2=maxvtxchi2,
        minComboPt=mincombopt,
        minZ=min_SVz,
        minFDCHI2=minFDCHI2,
        maxIP=maxIP,
        maxChi2CorrMuon=maxChi2Corr,
        minMuonNN=minMuonNN,
        useNN=useMuonNN,
        minPVZ=min_PVz,
        maxPVZ=max_PVz,
        enable_monitoring=is_allen_standalone() and enable_monitoring)


@configurable
def make_SMOG2_dimuon_highmass_line(secondary_vertices,
                                    long_tracks,
                                    muonid,
                                    maxTrackChi2Ndf,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None,
                                    name="Hlt1SMOG2_DiMuonHighMassLine",
                                    min_z=-537.5,
                                    max_z=-337.5,
                                    pre_scaler=1.,
                                    post_scaler=1.,
                                    maxChi2Corr=1.8,
                                    enable_monitoring=True,
                                    enable_tupling=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2_dimuon_highmass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minZ=min_z,
        maxZ=max_z,
        maxChi2Corr=maxChi2Corr,
        maxTrackChi2Ndf=maxTrackChi2Ndf,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling)


@configurable
def make_SMOG2_jpsitomumu_tap_line(secondary_vertices,
                                   long_tracks,
                                   muonid,
                                   maxTrackChi2Ndf,
                                   pre_scaler_hash_string=None,
                                   post_scaler_hash_string=None,
                                   name="Hlt1SMOG2_JpsiToMuMuTaPLine",
                                   min_z=-537.5,
                                   max_z=-337.5,
                                   pre_scaler=1.,
                                   post_scaler=1.,
                                   maxChi2Corr=1.8,
                                   minMuonNN=0.1,
                                   useMuonNN=False,
                                   enable_monitoring=True,
                                   enable_tupling=False,
                                   posTag=True):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        SMOG2jpsitomumu_tap_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        dev_muonidnn_t=muonid["dev_muonidnn"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        JpsiMinZ=min_z,
        JpsiMaxZ=max_z,
        posTag=posTag,
        mutagMaxChi2Corr=maxChi2Corr,
        minMuonNN=minMuonNN,
        useNN=useMuonNN,
        maxTrackChi2Ndf=maxTrackChi2Ndf,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling)


@configurable
def make_SMOG2_minimum_bias_line(velo_tracks,
                                 velo_states,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 name="Hlt1SMOG2_MinimumBias",
                                 min_z=-537.5,
                                 max_z=-337.5,
                                 pre_scaler=0.00003,
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


def make_SMOG2_ditrack_line(
        secondary_vertices,
        maxTrackChi2Ndf,
        m1=-1.,
        m2=-1.,
        minMdipion=0.,
        mMother=-1.,
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        name="Hlt1_SMOG2_DiTrack",
        mWindow=150.,
        minTrackP=3000.,
        minTrackPt=400.,
        minEitherTrackPt=400.,
        minTrackIPCHI2=0.,
        maxTrackIPCHI2=999999.,
        minFDCHI2=-10.,
        maxFDCHI2=999999.,
        maxGhostProb=0.3,
        min_z=-537.5,
        max_z=-337.5,
        pre_scaler=1.,
        post_scaler=1.,
        enable_tupling=False,
        enable_monitoring=True,
):

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
        minMdipion=minMdipion,
        mMother=mMother,
        massWindow=mWindow,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt,
        minTrackIPCHI2=minTrackIPCHI2,
        maxTrackIPCHI2=maxTrackIPCHI2,
        minEitherTrackPt=minEitherTrackPt,
        minZ=min_z,
        maxZ=max_z,
        minFDCHI2=minFDCHI2,
        maxFDCHI2=maxFDCHI2,
        maxTrackChi2Ndf=maxTrackChi2Ndf,
        maxGhostProb=maxGhostProb,
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring)


def make_SMOG2_kstopipi_line(secondary_vertices,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             name="Hlt1_SMOG2_KsPiPi",
                             min_z=-537.5,
                             max_z=-337.5,
                             minTrackPt=250.,
                             minMass=400.,
                             pre_scaler=1.,
                             post_scaler=1.,
                             enable_monitoring=True,
                             enable_tupling=False):

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
        minMass=minMass,
        minTrackPt=minTrackPt,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling)


def make_SMOG2_singletrack_line(long_tracks,
                                long_track_particles,
                                maxChi2Ndof,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                name="Hlt1_SMOG2_SingleTrack",
                                min_z=-537.5,
                                max_z=-337.5,
                                minPt=1.5,
                                maxGhostProb=0.3,
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
        maxChi2Ndof=maxChi2Ndof,
        minPt=minPt,
        maxGhostProb=maxGhostProb,
        minBPVz=min_z,
        maxBPVz=max_z)


def make_SMOG2_single_muon_line(long_tracks,
                                long_track_particles,
                                muonid,
                                maxChi2Ndof,
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None,
                                name="Hlt1_SMOG2_SingleMuon",
                                MinPt=700,
                                maxChi2Corr=1.8,
                                minMuonNN=0.1,
                                useMuonNN=False,
                                min_z=-537.5,
                                max_z=-337.5,
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
        dev_chi2muon_t=muonid["dev_chi2corr"],
        dev_muonidnn_t=muonid["dev_muonidnn"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        maxChi2Ndof=maxChi2Ndof,
        minBPVz=min_z,
        maxBPVz=max_z,
        MinPt=MinPt,
        maxChi2Corr=maxChi2Corr,
        minMuonNN=minMuonNN,
        useNN=useMuonNN)
