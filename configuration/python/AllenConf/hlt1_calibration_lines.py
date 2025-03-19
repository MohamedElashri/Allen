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
    d2kpi_line_t, dst_d2kpi_line_t, passthrough_line_t, rich_1_line_t,
    rich_2_line_t, displaced_di_muon_mass_line_t,
    di_muon_mass_alignment_line_t, two_calo_clusters_line_t, odin_calib_line_t)
from AllenConf.utils import initialize_number_of_events, line_maker
from AllenConf.odin import decode_odin
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


@configurable
def make_pi02gammagamma_line(calo,
                             velo_tracks,
                             pvs,
                             name="Hlt1Pi02GammaGamma",
                             pre_scaler=0.05,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             enable_tupling=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_calo_clusters_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_velo_tracks_t=velo_tracks["dev_velo_tracks_view"],
        dev_particle_container_t=calo["dev_multi_event_diphotons"],
        dev_cluster_particle_container_t=calo[
            "dev_multi_event_neutral_particles"],
        host_number_of_svs_t=calo["host_ecal_number_of_twoclusters"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        minMass=50,  #MeV
        maxMass=300,  #MeV
        minEt_clusters=400,  #MeV
        minE19_clusters=0.7,
        minPtEta=200,  #Pi0Pt>minPtEta*(10-Pi0Eta)
        max_n_pvs=1,
        enable_tupling=enable_tupling)


def make_dst_line(dstars,
                  name="Hlt1DstD0Pi",
                  enable_monitoring=True,
                  enable_tupling=False,
                  pre_scaler_hash_string=None,
                  post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        dst_d2kpi_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=dstars["host_number_of_sv_track_combinations"],
        dev_particle_container_t=dstars["dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_d2kpi_align_line(long_tracks,
                          secondary_vertices,
                          name="Hlt1D2KPiAlignment",
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
        minComboPt=2000.,  #MeV
        maxVertexChi2=10.,
        maxDOCA=0.1,  #mm
        minTrackPt=1000.,  #MeV
        minTrackP=3000.,  #MeV
        massWindow=60.,  #MeV
        minTrackIP=0.07,  #mm
        ctIPScale=2.,
        minDira=0.9995,
        minEta=2.,
        maxEta=5.,
        minZ=-341.,  #mm
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


@configurable
def make_passthrough_line(name="Hlt1Passthrough",
                          pre_scaler=0.0001,
                          pre_scaler_hash_string=None,
                          post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        passthrough_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_rich_line(line_type,
                   long_tracks,
                   long_track_particles,
                   name,
                   pre_scaler,
                   post_scaler,
                   pre_scaler_hash_string=None,
                   post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        line_type,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_rich_1_line(long_tracks,
                     long_track_particles,
                     name="Hlt1RICH1Alignment",
                     pre_scaler=1.0,
                     post_scaler=1.0,
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None):
    return make_rich_line(rich_1_line_t, long_tracks, long_track_particles,
                          name, pre_scaler, post_scaler,
                          pre_scaler_hash_string, post_scaler_hash_string)


def make_rich_2_line(long_tracks,
                     long_track_particles,
                     name="Hlt1RICH2Alignment",
                     pre_scaler=1.0,
                     post_scaler=1.0,
                     pre_scaler_hash_string=None,
                     post_scaler_hash_string=None):
    return make_rich_line(rich_2_line_t, long_tracks, long_track_particles,
                          name, pre_scaler, post_scaler,
                          pre_scaler_hash_string, post_scaler_hash_string)


def make_displaced_dimuon_mass_line(long_tracks,
                                    secondary_vertices,
                                    name="Hlt1DisplacedDiMuonAlignment",
                                    pre_scaler=1.0,
                                    post_scaler=1.0,
                                    pre_scaler_hash_string=None,
                                    post_scaler_hash_string=None):

    number_of_events = initialize_number_of_events()

    return make_algorithm(
        displaced_di_muon_mass_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + '_pre',
        post_scaler_hash_string=post_scaler_hash_string or name + '_post')


def make_di_muon_mass_align_line(long_tracks,
                                 secondary_vertices,
                                 muonid,
                                 pre_scaler=1.0,
                                 post_scaler=1.0,
                                 minMass=2996.,
                                 maxMass=3196.,
                                 maxDoca=0.2,
                                 maxVertexChi2=10.,
                                 minHighMassTrackPt=1000.,
                                 minHighMassTrackP=6000.,
                                 minIP=0.07,
                                 minFdChi2=5.,
                                 minDira=0.9995,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 name="Hlt1DiMuonHighMassAlignment"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_alignment_line_t,
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
        minMass=minMass,
        maxMass=maxMass,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        minIP=minIP,
        minFdChi2=minFdChi2,
        minDira=minDira)


@configurable
def make_tae_line(prefilters, accept_sub_events=False, pre_scaler=1):
    from .odin import tae_filter
    tf = tae_filter(accept_sub_events=accept_sub_events)
    return line_maker(
        make_passthrough_line(
            name="Hlt1TAEPassthrough", pre_scaler=pre_scaler),
        prefilter=prefilters + [tf])


@configurable
def make_odin_calib_line(pre_scaler=1.,
                         post_scaler=1.,
                         pre_scaler_hash_string=None,
                         post_scaler_hash_string=None,
                         name="Hlt1ODINCalib"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    return make_algorithm(
        odin_calib_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin["dev_odin_data"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post")
