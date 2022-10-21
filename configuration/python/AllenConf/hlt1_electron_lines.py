###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    track_electron_mva_line_t, single_high_pt_electron_line_t,
    displaced_dielectron_line_t, displaced_leptons_line_t,
    single_high_et_line_t, prompt_vertex_evaluator_t,
    lowmass_noip_dielectron_line_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def make_track_electron_mva_line(long_tracks,
                                 long_track_particles,
                                 calo,
                                 name="Hlt1TrackElectronMVA",
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None):
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
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_single_high_pt_electron_line(long_tracks,
                                      long_track_particles,
                                      calo,
                                      name="Hlt1SingleHighPtElectron",
                                      pre_scaler_hash_string=None,
                                      post_scaler_hash_string=None):
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
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


def make_displaced_dielectron_line(long_tracks,
                                   secondary_vertices,
                                   calo,
                                   name="Hlt1DisplacedDielectron",
                                   pre_scaler_hash_string=None,
                                   post_scaler_hash_string=None):
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
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"])


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


def make_lowmass_noip_dielectron_line(
        long_tracks,
        secondary_vertices,
        calo,
        minMass,
        maxMass,
        minPTprompt,
        minPTdisplaced,
        minIPChi2Threshold,
        selectPrompt=True,
        is_same_sign=False,
        enable_monitoring=False,
        name="Hlt1LowMassNoipDielectron",
        pre_scaler_hash_string="lowmass_noip_dielectron_line_pre",
        pre_scaler=1.0,
        post_scaler_hash_string="lowmass_noip_dielectron_line_post"):
    number_of_events = initialize_number_of_events()

    prompt_vertex_evaluator = make_algorithm(
        prompt_vertex_evaluator_t,
        name="prompt_vertex_evaluator",
        dev_consolidated_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        MinIPChi2Threshold=minIPChi2Threshold,
        MinPTprompt=minPTprompt,
        MinPTdisplaced=minPTdisplaced,
    )

    return make_algorithm(
        lowmass_noip_dielectron_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_track_isElectron_t=calo["dev_track_isElectron"],
        dev_brem_corrected_pt_t=calo["dev_brem_corrected_pt"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        MinMass=minMass,
        MaxMass=maxMass,
        selectPrompt=selectPrompt,
        ss_on=is_same_sign,
        enable_monitoring=enable_monitoring,
        dev_vertex_passes_prompt_selection_t=prompt_vertex_evaluator.
        dev_vertex_passes_prompt_selection_t,
        dev_vertex_passes_displaced_selection_t=prompt_vertex_evaluator.
        dev_vertex_passes_displaced_selection_t)
