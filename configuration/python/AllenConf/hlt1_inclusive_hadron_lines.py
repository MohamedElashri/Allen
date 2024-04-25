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
    kstopipi_line_t, track_mva_line_t, two_track_mva_line_t,
    two_track_mva_evaluator_t, two_track_line_ks_t, lambda2ppi_line_t,
    lambda_ll_detached_track_line_t, xi_omega_lll_line_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm
from AllenCore.configuration_options import is_allen_standalone


def make_kstopipi_line(long_tracks,
                       secondary_vertices,
                       pre_scaler_hash_string=None,
                       post_scaler_hash_string=None,
                       post_scaler=1.0,
                       name='Hlt1KsToPiPi_{hash}',
                       double_muon_misid=False,
                       enable_monitoring=True):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        kstopipi_line_t,
        name=name,
        double_muon_misid=double_muon_misid,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        post_scaler=post_scaler)


def make_track_mva_line(long_tracks,
                        long_track_particles,
                        pre_scaler_hash_string=None,
                        post_scaler_hash_string=None,
                        name='Hlt1TrackMVA_{hash}',
                        enable_tupling=False,
                        enable_monitoring=True,
                        alpha=296,
                        maxGhostProb=0.5):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        track_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        alpha=alpha,
        maxGhostProb=maxGhostProb)


def make_two_track_mva_line(long_tracks,
                            secondary_vertices,
                            pre_scaler_hash_string=None,
                            post_scaler_hash_string=None,
                            name='Hlt1TwoTrackMVA_{hash}',
                            enable_tupling=False,
                            enable_monitoring=True,
                            minMVA=0.9569,
                            maxGhostProb=0.5):
    number_of_events = initialize_number_of_events()

    two_track_mva_evaluator = make_algorithm(
        two_track_mva_evaluator_t,
        name='two_track_mva_evaluator_{hash}',
        dev_consolidated_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"])

    return make_algorithm(
        two_track_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_two_track_mva_evaluation_t=two_track_mva_evaluator.
        dev_two_track_mva_evaluation_t,
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        minMVA=minMVA,
        maxGhostProb=maxGhostProb)


def make_two_track_line_ks(long_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           name='Hlt1TwoTrackKs_{hash}',
                           enable_tupling=False,
                           minTrackPt_piKs=470,
                           minTrackP_piKs=5000,
                           minTrackIPChi2_Ks=50,
                           maxEta_Ks=4.2,
                           min_combip=0.72,
                           minComboPt_Ks=100):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_track_line_ks_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minTrackPt_piKs=minTrackPt_piKs,
        minTrackP_piKs=minTrackP_piKs,
        minTrackIPChi2_Ks=minTrackIPChi2_Ks,
        maxEta_Ks=maxEta_Ks,
        min_combip=min_combip,
        minComboPt_Ks=minComboPt_Ks,
        enable_tupling=enable_tupling)


def make_lambda2ppi_line(secondary_vertices,
                         name,
                         pre_scaler_hash_string=None,
                         post_scaler_hash_string=None,
                         minPVZ=-200.,
                         maxPVZ=200.,
                         maxVtxChi2=10.,
                         minVZ=-80.,
                         minDIRA=0.9997,
                         minpipchi2=12.,
                         minpiipchi2=32.,
                         minpipt=80.,
                         enable_tupling=False,
                         enable_monitoring=False):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        lambda2ppi_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        minPVZ=minPVZ,
        maxPVZ=maxPVZ,
        L_VZ_min=minVZ,
        L_VCHI2_max=maxVtxChi2,
        L_BPVDIRA_min=minDIRA,
        L_p_MIPCHI2_min=minpipchi2,
        L_pi_MIPCHI2_min=minpiipchi2,
        L_pi_PT_min=minpipt,
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring)


def make_lambda_ll_detached_track_line(sv_track_candidates,
                                       name,
                                       pre_scaler_hash_string=None,
                                       post_scaler_hash_string=None,
                                       enable_monitoring=False,
                                       enable_tupling=False):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        lambda_ll_detached_track_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=sv_track_candidates[
            "host_number_of_sv_track_combinations"],
        dev_particle_container_t=sv_track_candidates[
            "dev_sv_track_combination"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        enable_monitoring=enable_monitoring,
        enable_tupling=enable_tupling)


def make_xi_omega_lll_line(sv_track_candidates,
                           name,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           enable_monitoring=False,
                           enable_tupling=False):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        xi_omega_lll_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=sv_track_candidates[
            "host_number_of_sv_track_combinations"],
        dev_particle_container_t=sv_track_candidates[
            "dev_sv_track_combination"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        enable_monitoring=enable_monitoring,
        enable_tupling=enable_tupling)
