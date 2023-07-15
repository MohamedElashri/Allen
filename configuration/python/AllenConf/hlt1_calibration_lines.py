###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    d2kpi_line_t, passthrough_line_t, rich_1_line_t, rich_2_line_t,
    displaced_di_muon_mass_line_t, di_muon_mass_alignment_line_t,
    two_calo_clusters_line_t)
from AllenConf.utils import initialize_number_of_events, line_maker
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


def make_pi02gammagamma_line(calo,
                             velo_tracks,
                             pvs,
                             name="Hlt1Pi02GammaGamma",
                             pre_scaler=1.,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        two_calo_clusters_line_t,
        name=name,
        pre_scaler=pre_scaler,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"],
        dev_ecal_number_of_clusters_t=calo["dev_ecal_num_clusters"],
        dev_ecal_twoclusters_t=calo["dev_ecal_twoclusters"],
        dev_ecal_twocluster_offsets_t=calo["dev_ecal_twocluster_offsets"],
        host_ecal_number_of_twoclusters_t=calo[
            "host_ecal_number_of_twoclusters"],
        dev_number_of_pvs_t=pvs["dev_number_of_multi_final_vertices"],
        minMass=50,  #MeV
        maxMass=300,  #MeV
        minEt_clusters=400,  #MeV
        minE19_clusters=0.7,
        minPtEta=200,  #Pi0Pt>minPtEta*(10-Pi0Eta)
        max_n_pvs=1,
        enable_tupling=False)


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
                                 pre_scaler=1.0,
                                 post_scaler=1.0,
                                 pre_scaler_hash_string=None,
                                 post_scaler_hash_string=None,
                                 minHighMassTrackPt=300.,
                                 minHighMassTrackP=6000.,
                                 maxDoca=0.2,
                                 maxVertexChi2=25.,
                                 minIPChi2=0.,
                                 minMass=9000.,
                                 name="Hlt1DiMuonHighMassAlignment"):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_alignment_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minMass=minMass,
        minIPChi2=minIPChi2)


@configurable
def make_tae_line(prefilters, accept_sub_events=True, pre_scaler=1):
    from .odin import tae_filter
    tf = tae_filter(accept_sub_events=accept_sub_events)
    return line_maker(
        make_passthrough_line(
            name="Hlt1TAEPassthrough", pre_scaler=pre_scaler),
        prefilter=prefilters + [tf])
