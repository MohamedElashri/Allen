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
    single_high_pt_muon_line_t, single_high_pt_muon_no_muid_line_t,
    low_pt_muon_line_t, di_muon_mass_line_t, di_muon_soft_line_t,
    low_pt_di_muon_line_t, track_muon_mva_line_t, di_muon_no_ip_line_t,
    one_muon_track_line_t, di_muon_drell_yan_line_t, displaced_di_muon_line_t,
    det_jpsitomumu_tap_line_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenCore.generator import make_algorithm
from PyConf.tonic import configurable
from AllenCore.configuration_options import is_allen_standalone


@configurable
def make_one_muon_track_line(muon_tracks,
                             dev_muon_tracks_offsets,
                             host_muon_total_number_of_tracks,
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
        dev_muon_tracks_t=muon_tracks,
        host_muon_total_number_of_tracks_t=host_muon_total_number_of_tracks,
        dev_muon_tracks_offsets_t=dev_muon_tracks_offsets)


@configurable
def make_single_high_pt_muon_line(long_tracks,
                                  long_track_particles,
                                  name="Hlt1SingleHighPtMuon",
                                  pre_scaler_hash_string=None,
                                  post_scaler_hash_string=None,
                                  enable_tupling=False,
                                  pre_scaler=1.,
                                  singleMinPt=6000):
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
        enable_tupling=enable_tupling,
        singleMinPt=singleMinPt)


@configurable
def make_single_high_pt_muon_no_muid_line(long_tracks,
                                          long_track_particles,
                                          name="Hlt1SingleHighPtMuonNoMuID",
                                          pre_scaler_hash_string=None,
                                          post_scaler_hash_string=None,
                                          pre_scaler=0.05,
                                          singleMinPt=8000):
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
            "dev_multi_event_basic_particles"],
        singleMinPt=singleMinPt)


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
                           muonid,
                           pre_scaler_hash_string=None,
                           post_scaler_hash_string=None,
                           enable_monitoring=True,
                           minHighMassTrackPt=300.,
                           minHighMassTrackP=6000.,
                           minMass=2700.,
                           maxDoca=0.2,
                           maxVertexChi2=25.,
                           minIPChi2=0.,
                           maxChi2Corr=1.8,
                           name="Hlt1DiMuonHighMass",
                           pre_scaler=1.,
                           enable_tupling=False):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_mass_line_t,
        name=name,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        pre_scaler=pre_scaler,
        minHighMassTrackPt=minHighMassTrackPt,
        minHighMassTrackP=minHighMassTrackP,
        minMass=minMass,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minIPChi2=minIPChi2,
        maxChi2Muon=maxChi2Corr,
        enable_tupling=enable_tupling)


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
                             muonid,
                             maxChi2Corr=1.8,
                             name="Hlt1TrackMuonMVA",
                             pre_scaler_hash_string=None,
                             post_scaler_hash_string=None,
                             enable_tupling=False,
                             pre_scaler=1.,
                             alpha=0.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        track_muon_mva_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=long_tracks[
            "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
            "dev_multi_event_basic_particles"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        maxChi2Muon=maxChi2Corr,
        pre_scaler_hash_string=pre_scaler_hash_string or name + "_pre",
        post_scaler_hash_string=post_scaler_hash_string or name + "_post",
        enable_tupling=enable_tupling,
        pre_scaler=pre_scaler,
        alpha=alpha)


@configurable
def make_di_muon_no_ip_line(long_tracks,
                            secondary_vertices,
                            muonid,
                            pre_scaler_hash_string="di_muon_no_ip_line_pre",
                            post_scaler_hash_string="di_muon_no_ip_line_post",
                            minTrackPtPROD=1000000.,
                            minTrackP=8000.,
                            maxDoca=.3,
                            maxVertexChi2=9.,
                            maxTrChi2=3.,
                            minPt=1000.,
                            minNN=0.2,
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
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        dev_muonid_nn_t=muonid["dev_muonid_response"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minTrackPtPROD=minTrackPtPROD,
        minTrackP=minTrackP,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        minNN=minNN,
        ss_on=ss_on,
        pre_scaler=pre_scaler,
        post_scaler=post_scaler)


@configurable
def make_di_muon_drell_yan_line(
        long_tracks,
        secondary_vertices,
        muonid,
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
        maxChi2Corr=2.2,
        pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        di_muon_drell_yan_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        minTrackP=minTrackP,
        minTrackPt=minTrackPt,
        maxTrackEta=maxTrackEta,
        maxDoca=maxDoca,
        maxVertexChi2=maxVertexChi2,
        maxChi2Muon=maxChi2Corr,
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
        muonid,
        maxChi2Corr=1.8,
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
        dev_track_offsets_t=long_tracks["dev_offsets_long_tracks"],
        dev_chi2muon_t=muonid["dev_chi2corr"],
        maxChi2Muon=maxChi2Corr,
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        pre_scaler=pre_scaler)


@configurable
def make_det_jpsitomumu_tap_line(
        long_tracks,
        secondary_vertices,
        pre_scaler_hash_string="jpsitomumutap_line_pre",
        post_scaler_hash_string='jpsitomumutap_line_post',
        name="Hlt1DetJPsiToMuMuTaP",
        JpsiMaxDoca=1.,
        JpsiMinFDChi2=50.,
        JpsiMinCosDira=0.99,
        JpsiMaxVChi2=15.,
        JpsiMinPt=1000.,
        JpsiMinMass=2950.,
        JpsiMaxMass=3250.,
        mutagMinP=3000.,
        mutagMinPt=1200.,
        mutagMinIPChi2=9.,
        muprobeMinIPChi2=9.,
        muprobeMinP=3000.,
        posTag=True,
        enable_monitoring=True,
        enable_tupling=False,
        pre_scaler=1.):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        det_jpsitomumu_tap_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
        dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string,
        JpsiMaxDoca=JpsiMaxDoca,
        JpsiMinFDChi2=JpsiMinFDChi2,
        JpsiMinCosDira=JpsiMinCosDira,
        JpsiMaxVChi2=JpsiMaxVChi2,
        JpsiMinPt=JpsiMinPt,
        JpsiMinMass=JpsiMinMass,
        JpsiMaxMass=JpsiMaxMass,
        mutagMinP=mutagMinP,
        mutagMinPt=mutagMinPt,
        mutagMinIPChi2=mutagMinIPChi2,
        muprobeMinIPChi2=muprobeMinIPChi2,
        muprobeMinP=muprobeMinP,
        posTag=posTag,
        enable_monitoring=is_allen_standalone() and enable_monitoring,
        enable_tupling=enable_tupling,
        pre_scaler=pre_scaler)
