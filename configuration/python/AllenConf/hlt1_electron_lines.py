###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.algorithms import (
    track_electron_mva_line_t, single_high_pt_electron_line_t,
    displaced_dielectron_line_t, displaced_leptons_line_t,
    single_high_et_line_t, lowmass_dielectron_line_t,
    highmass_dielectron_line_t, di_electron_soft_line_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenCore.configuration_options import is_allen_standalone
from PyConf.tonic import configurable


@configurable
def make_track_electron_mva_line(long_tracks,
                                 long_track_particles,
                                 calo,
                                 name="Hlt1TrackElectronMVA",
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 enable_tupling=True,
                                 alpha=0.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        track_electron_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        enable_tupling=True,
        alpha=alpha)


def make_single_high_pt_electron_line(long_tracks,
                                      long_track_particles,
                                      calo,
                                      name="Hlt1SingleHighPtElectron",
                                      pre_scaler_hash_string=None,
                                      post_scaler_hash_string=None,
                                      enable_tupling=False,
                                      singleMinPt=6000):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_pt_electron_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        enable_tupling=enable_tupling,
        singleMinPt=singleMinPt)


def make_displaced_dielectron_line(long_tracks,
                                   secondary_vertices,
                                   calo,
                                   name="Hlt1DisplacedDiElectron",
                                   pre_scaler_hash_string=None,
                                   post_scaler_hash_string=None,
                                   MinPT=500,
                                   MinIPChi2=7.4,
                                   enable_tupling=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        displaced_dielectron_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        MinPT=MinPT,
        MinIPChi2=MinIPChi2,
        enable_tupling=enable_tupling)


def make_displaced_leptons_line(long_tracks,
                                long_track_particles,
                                calo,
                                name="Hlt1DisplacedLeptons",
                                pre_scaler_hash_string=None,
                                post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        displaced_leptons_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_track_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_single_high_et_line(velo_tracks,
                             calo,
                             name="Hlt1SingleHighEt",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_et_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_velo_tracks_offsets_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_brem_ET_t=calo["dev_brem_ET"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")


def make_lowmass_dielectron_line(
        long_tracks,
        secondary_vertices,
        electronid_nn,
        calo,
        minMass,
        maxMass,
        minPTprompt,
        minPTdisplaced,
        trackIPChi2Threshold,
        selectPrompt=True,
        is_same_sign=False,
        enable_monitoring=True,
        enable_tupling=False,
        useNN=False,
        nnCut=0.7,
        name="Hlt1LowMassDiElectron",
        pre_scaler_hash_string="lowmass_dielectron_line_pre",
        pre_scaler=1.,
        post_scaler=1.,
        post_scaler_hash_string="lowmass_dielectron_line_post"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        lowmass_dielectron_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_electronid_evaluation_t=electronid_nn["dev_electronid_response"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        selectPrompt=selectPrompt,
        MinMass=minMass,
        MaxMass=maxMass,
        ss_on=is_same_sign,
        UseNN=useNN,
        NNCut=nnCut,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        MinPTprompt=minPTprompt,
        MinPTdisplaced=minPTdisplaced,
        TrackIPChi2Threshold=trackIPChi2Threshold)


def make_highmass_dielectron_line(
        long_tracks,
        secondary_vertices,
        calo,
        minMass=8000,
        maxMass=140000,
        is_same_sign=False,
        enable_monitoring=True,
        enable_tupling=False,
        name="Hlt1HighMassDielectron",
        pre_scaler_hash_string="highmass_dielectron_line_pre",
        pre_scaler=1.,
        post_scaler=1.,
        post_scaler_hash_string="highmass_dielectron_line_post"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        highmass_dielectron_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minMass=minMass,
        maxMass=maxMass,
        enable_monitoring=enable_monitoring,
        OppositeSign=(not is_same_sign))


def make_di_electron_soft_line(long_tracks,
                               secondary_vertices,
                               calo,
                               name="Hlt1DiElectronSoft",
                               pre_scaler_hash_string=None,
                               enable_tupling=False,
                               enable_monitoring=False,
                               post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_electron_soft_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        enable_monitoring=False,
        enable_tupling=False,
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
