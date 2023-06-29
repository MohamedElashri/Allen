###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.algorithms import (
    single_high_pt_muon_line_t, single_high_pt_muon_no_muid_line_t,
    low_pt_muon_line_t, di_muon_mass_line_t, di_muon_soft_line_t,
    low_pt_di_muon_line_t, track_muon_mva_line_t, di_muon_no_ip_line_t,
    one_muon_track_line_t, di_muon_drell_yan_line_t, displaced_di_muon_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


@configurable
def make_one_muon_track_line(number_of_muon_tracks,
                             muon_tracks,
                             dev_output_buffer,
                             host_total_sum_holder,
                             name="Hlt1OneMuonTrack",
                             pre_scaler=1.,
                             post_scaler=1.,
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        one_muon_track_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        dev_muon_number_of_tracks_t=number_of_muon_tracks,
        dev_muon_tracks_t=muon_tracks,
        host_muon_total_number_of_tracks_t=host_total_sum_holder,
        dev_muon_tracks_offsets_t=dev_output_buffer)


@configurable
def make_single_high_pt_muon_line(long_tracks,
                                  long_track_particles,
                                  name="Hlt1SingleHighPtMuon",
                                  pre_scaler_hash_string=None,
                                  post_scaler_hash_string=None,
                                  enable_tupling=False,
                                  pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_pt_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        enable_tupling=enable_tupling)


@configurable
def make_single_high_pt_muon_no_muid_line(long_tracks,
                                          long_track_particles,
                                          name="Hlt1SingleHighPtMuonNoMuID",
                                          pre_scaler_hash_string=None,
                                          post_scaler_hash_string=None,
                                          pre_scaler=0.05):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        single_high_pt_muon_no_muid_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


@configurable
def make_low_pt_muon_line(long_tracks,
                          long_track_particles,
                          name="Hlt1LowPtMuon",
                          pre_scaler=1.,
                          post_scaler=1.,
                          pre_scaler_hash_string=None,
                          post_scaler_hash_string=None):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        low_pt_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        post_scaler=post_scaler,
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"])


@configurable
def make_di_muon_mass_line(long_tracks,
                           secondary_vertices,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           enable_monitoring=False,
                           minHighMassTrackPt=300.,
                           minHighMassTrackP=6000.,
                           minMass=2700.,
                           maxDoca=0.2,
                           maxVertexChi2=25.,
                           minIPChi2=0.,
                           name="Hlt1DiMuonHighMass",
                           pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        minMass=minMass,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minIPChi2=minIPChi2)


@configurable
def make_di_muon_soft_line(long_tracks,
                           secondary_vertices,
                           name="Hlt1DiMuonSoft",
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_soft_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler)


@configurable
def make_low_pt_di_muon_line(long_tracks,
                             secondary_vertices,
                             name="Hlt1LowPtDiMuon",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        low_pt_di_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler)


@configurable
def make_track_muon_mva_line(long_tracks,
                             long_track_particles,
                             name="Hlt1TrackMuonMVA",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             enable_tupling=False,
                             pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        track_muon_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        enable_tupling=enable_tupling,
        pre_scaler=pre_scaler)


@configurable
def make_di_muon_no_ip_line(long_tracks,
                            secondary_vertices,
                            pre_scaler_hash_string="di_muon_no_ip_line_pre",
                            post_scaler_hash_string="di_muon_no_ip_line_post",
                            minTrackPtPROD=1000000.,
                            minTrackP=5000.,
                            maxDoca=.3,
                            maxVertexChi2=9.,
                            maxTrChi2=3.,
                            minPt=1000.,
                            name="Hlt1DiMuonNoIP",
                            ss_on=False,
                            enable_monitoring=True,
                            enable_tupling=False,
                            pre_scaler=1.,
                            post_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_no_ip_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minTrackPtPROD=minTrackPtPROD,
        minTrackP=minTrackP,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        maxTrChi2=maxTrChi2,
        ss_on=ss_on,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler)


@configurable
def make_di_muon_drell_yan_line(
        long_tracks,
        secondary_vertices,
        pre_scaler_hash_string="di_muon_drell_yan_line_pre",
        post_scaler_hash_string="di_muon_drell_yan_line_post",
        minTrackPt=1200.,
        minTrackP=15000.,
        maxTrackEta=4.9,
        maxDoca=.15,
        maxVertexChi2=16.,
        name="Hlt1DiMuonDrellYan",
        OppositeSign=True,
        enable_monitoring=False,
        enable_tupling=False,
        minMass=5000.,
        maxMass=250000,
        pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_drell_yan_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt,
        maxTrackEta=maxTrackEta,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        OppositeSign=OppositeSign,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        minMass=minMass,
        maxMass=maxMass,
        pre_scaler=pre_scaler)


@configurable
def make_displaced_dimuon_line(
        long_tracks,
        secondary_vertices,
        pre_scaler_hash_string="displaced_di_muon_line_pre",
        post_scaler_hash_string='displaced_di_muon_line_post',
        name="Hlt1DisplacedDiMuon",
        enable_monitoring=True,
        pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        displaced_di_muon_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        pre_scaler=pre_scaler)
