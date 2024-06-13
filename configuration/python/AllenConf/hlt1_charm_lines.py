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
    d2kk_line_t, d2pipi_line_t, d2kpi_line_t, two_ks_line_t, d2kshh_line_t,
    two_track_mva_charm_xsec_line_t, two_track_mva_evaluator_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from AllenCore.configuration_options import is_allen_standalone


def make_d2kpi_line(long_tracks,
                    secondary_vertices,
                    name="Hlt1D2KPi",
                    enable_monitoring=True,
                    pre_scaler_hash_string=None,
                    post_scaler_hash_string=None,
                    enable_tupling=False):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2kpi_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_d2kk_line(long_tracks,
                   secondary_vertices,
                   name='Hlt1D2KK_{hash}',
                   enable_monitoring=True,
                   pre_scaler_hash_string=None,
                   post_scaler_hash_string=None,
                   enable_tupling=False,
                   charm_track_ip=0.06,
                   charm_track_pt=800):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2kk_line_t,
        name=name,
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        minTrackPt=charm_track_pt,
        minTrackIP=charm_track_ip)


def make_d2pipi_line(long_tracks,
                     secondary_vertices,
                     name='Hlt1D2PiPi_{hash}',
                     enable_monitoring=True,
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None,
                     enable_tupling=False,
                     charm_track_ip=0.06,
                     charm_track_pt=800):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2pipi_line_t,
        name=name,
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        minTrackPt=charm_track_pt,
        minTrackIP=charm_track_ip)


def make_d2kpi_line(long_tracks,
                    secondary_vertices,
                    name="Hlt1D2KPi",
                    enable_monitoring=True,
                    pre_scaler_hash_string=None,
                    post_scaler_hash_string=None,
                    enable_tupling=False,
                    charm_track_ip=0.06,
                    charm_track_pt=800):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2kpi_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        minTrackPt=charm_track_pt,
        minTrackIP=charm_track_ip)


def make_two_ks_line(long_tracks,
                     secondary_vertices,
                     name='Hlt1TwoKs_{hash}',
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_ks_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_sv_pairs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_sv_combos_view"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
    )


def make_two_track_mva_charm_xsec_line(long_tracks,
                                       secondary_vertices,
                                       name='Hlt1TwoTrackMVACharmXSec_{hash}',
                                       pre_scaler_hash_string=None,
                                       post_scaler_hash_string=None,
                                       pre_scaler=1.0):
    number_of_events = initialize_number_of_events()

    two_track_mva_evaluator = make_algorithm(
        two_track_mva_evaluator_t,
        name='two_track_mva_evaluator_{hash}',
        dev_consolidated_svs_t=secondary_vertices["dev_consolidated_svs"],
        dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
    )

    return make_algorithm(
        two_track_mva_charm_xsec_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post',
        pre_scaler=pre_scaler,
        dev_two_track_mva_evaluation_t=two_track_mva_evaluator.
        dev_two_track_mva_evaluation_t,
    )


def make_d2kshh_line(
        long_tracks,
        secondary_vertices,
        name="Hlt1D2Kshh_{hash}",
        pre_scaler_hash_string=None,
        post_scaler_hash_string=None,
        enable_monitoring=False,
        enable_tupling=False,
        maxVertexChi2=20,
        maxDOCA=0.05,
        minTrackPt_piKs=200.,
        minTrackP_piKs=1500.,
        minTrackIP_Ks=0.2,
        minComboPt_Ks=200.,
        minEta_Ks=2.0,
        maxEta_Ks=5.0,
        minM_Ks=455.,
        maxM_Ks=545.,
        maxDOCA_hh=0.05,
        minEta_hh=2.0,
        maxEta_hh=5.0,
        minTrackPt_hh=250.,
        minTrackP_hh=1500.,
        minTrackIP_hh=0.06,
        minComboPt_D0=1500.,
        minCTau_D0=0.5 * 0.1229,  # 0.5 * D0 ctau
        massWindow=100.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        d2kshh_line_t,
        name=name,
        enable_tupling=enable_tupling,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices[
            "host_number_of_sv_sv_combinations"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_sv_combos_view"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        # Filter properties
        maxVertexChi2=maxVertexChi2,
        maxDOCA=maxDOCA,
        # KS0 properties
        minTrackPt_Ks=minTrackPt_piKs,
        minTrackP_Ks=minTrackP_piKs,
        minTrackIP_Ks=minTrackIP_Ks,
        minComboPt_Ks=minComboPt_Ks,
        minEta_Ks=minEta_Ks,
        maxEta_Ks=maxEta_Ks,
        minM_Ks=minM_Ks,
        maxM_Ks=maxM_Ks,
        # hh properties
        maxDOCA_hh=maxDOCA_hh,
        minEta_hh=minEta_hh,
        maxEta_hh=maxEta_hh,
        minTrackP_hh=minTrackP_hh,
        minTrackPt_hh=minTrackPt_hh,
        minTrackIP_hh=minTrackIP_hh,
        # D0 properties
        minComboPt_D0=minComboPt_D0,
        minCTau_D0=minCTau_D0,
        massWindow=massWindow)
