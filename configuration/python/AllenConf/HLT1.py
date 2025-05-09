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
from AllenConf.utils import line_maker, make_invert_event_list
from AllenConf.odin import make_bxtype, odin_error_filter, tae_filter, make_event_type, make_odin_orbit
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node, make_dq_node
from AllenConf.hlt1_inclusive_hadron_lines import *
from AllenConf.hlt1_charm_lines import *
from AllenConf.hlt1_calibration_lines import *
from AllenConf.hlt1_muon_lines import *
from AllenConf.hlt1_electron_lines import *
from AllenConf.hlt1_monitoring_lines import *
from AllenConf.hlt1_smog2_lines import *
from AllenConf.hlt1_downstream_lines import *
from AllenConf.filters import *
from AllenConf.hlt1_charged_kaon_lines import *

from AllenConf.hlt1_photon_lines import make_diphotonhighmass_line
from AllenConf.persistency import make_persistency
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.enum_types import TrackingType, includes_matching
from AllenConf.get_thresholds import get_thresholds
import re


def default_physics_lines(reconstructed_objects, with_calo, with_muon,
                          with_v0s, thresholds, enable_tupling, chi2_cuts):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    pvs = reconstructed_objects["pvs"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    prompt_dihadrons = reconstructed_objects[
        "prompt_dihadron_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]
    v0s = reconstructed_objects["v0_secondary_vertices"]
    lambda_track_from_c = reconstructed_objects["lambda_track_from_c"]
    v0_twotrack_pairs = reconstructed_objects["v0_sv_twotrack_pairs"]
    dstars = reconstructed_objects["dstars"]
    three_body_svs = reconstructed_objects["three_body_svs"]
    v0_pairs = reconstructed_objects["v0_pairs"]
    v0_hh_pairs = reconstructed_objects["v0_hh_pairs"]
    phi_plus_track = reconstructed_objects["phi_plus_track"]
    dihadrons_noipcut = reconstructed_objects["dihadrons_noipcut"]
    muon_stubs = reconstructed_objects["muon_stubs"]

    lines = [
        make_track_mva_line(
            long_tracks,
            long_track_particles,
            maxChi2Ndof=chi2_cuts.Hlt1TrackMVA_maxChi2Ndof,
            name="Hlt1TrackMVA",
            enable_tupling=enable_tupling,
            alpha=thresholds.TrackMVA_alpha,
            maxGhostProb=thresholds.TrackMVA_maxGhostProb),
        make_two_track_mva_line(
            long_tracks,
            dihadrons,
            name="Hlt1TwoTrackMVA",
            enable_tupling=enable_tupling,
            minMVA=thresholds.TwoTrackMVA_minMVA,
            maxGhostProb=thresholds.TwoTrackMVA_maxGhostProb),
        make_d2kk_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2KK",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.D2HH_track_ip,
            charm_track_pt=thresholds.D2HH_track_pt),
        make_d2kpi_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2KPi",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.D2HH_track_ip,
            charm_track_pt=thresholds.D2HH_track_pt),
        make_d2pipi_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2PiPi",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.D2HH_track_ip,
            charm_track_pt=thresholds.D2HH_track_pt),
        make_dst_line(dstars, name="Hlt1Dst2D0Pi"),
        make_diproton_highmass_line(
            prompt_dihadrons,
            name="Hlt1DiProtonHighMass",
            minPT_p=thresholds.DiProtonHighMass_P_minPt,
            minPT_pp=thresholds.DiProtonHighMass_PP_minPt,
            pre_scaler=1.,
            enable_tupling=enable_tupling),
        make_kplus_to_piee_line(
            three_body_svs, name="Hlt1Kplus2PiEE", enable_monitoring=False),
        make_kplus_to_pimumu_line(
            three_body_svs, name="Hlt1Kplus2PiMuMu", enable_monitoring=False),
        make_kplus_to_3pi_line(
            three_body_svs, name="Hlt1Kplus2PiPiPi", enable_monitoring=False),
        make_tautophimu_line(
            phi_plus_track,
            name="Hlt1TauToPhiMu",
            enable_tupling=enable_tupling),
    ]

    if 'downstream_tracks' in reconstructed_objects and 'downstream_secondary_vertices' in reconstructed_objects:
        lines += [
            make_downstream_kshort_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                mva_ks_threshold=0.55,
                mva_detached_ks_threshold=thresholds.
                DownstreamKsToPiPi_minMVA_detached,
                name="Hlt1DownstreamKsToPiPi",
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_downstream_lambda_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                mva_l0_threshold=0.5,
                mva_detached_l0_threshold=thresholds.
                DownstreamLambdaToPPi_minMVA_detached,
                name="Hlt1DownstreamLambdaToPPi",
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_downstream_kshort_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                post_scaler=0.001,
                mva_ks_threshold=0.5,
                mva_detached_ks_threshold=0.,
                name="Hlt1DownstreamPromptKsToPiPi",
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_downstream_lambda_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                post_scaler=0.001,
                mva_l0_threshold=0.5,
                mva_detached_l0_threshold=0.,
                name="Hlt1DownstreamPromptLambdaToPPi",
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_downstream_gamma_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                minPt=thresholds.DownstreamGammaToEE_minPt,
                name="Hlt1DownstreamGammaToEE",
                post_scaler=0.2,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_BuSca_line(  # BuSca HLT1 Monitoring Line / Trigger disabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_secondary_vertices'],
                name="Hlt1DownstreamBuScaMonitoring",
                line_type="monitoring",
                enable_trigger=False),
            make_BuSca_line(  # BuSca HLT1 Monitoring Line with same sign reconstuction / Trigger disabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                name="Hlt1DownstreamBuScaMonitoringSameSign",
                line_type="monitoring",
                enable_trigger=False),
            make_BuSca_line(  # BuSca HLT1 Monitoring Line for clean region / Trigger disabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_secondary_vertices'],
                name="Hlt1DownstreamBuScaMonitoringCleanRegion",
                line_type="monitoring",
                histogram_ks_mass_min=800,
                histogram_ks_mass_nbins=50,
                histogram_ks_fd_min=1200,
                histogram_ks_fd_max=1600,
                histogram_ks_fd_nbins=10,
                clean_region=True,
                enable_trigger=False),
            make_BuSca_line(  # BuSca HLT1 Monitoring Line for clean region with same sign reconstuction / Trigger disabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                name="Hlt1DownstreamBuScaMonitoringCleanRegionSameSign",
                line_type="monitoring",
                enable_trigger=False,
                histogram_ks_mass_min=800,
                histogram_ks_mass_nbins=50,
                histogram_ks_fd_min=1200,
                histogram_ks_fd_max=1600,
                histogram_ks_fd_nbins=10,
                clean_region=True),
            make_BuSca_line(  # BuSca HLT1 HH with PiPi mass hypo. / Trigger enabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_secondary_vertices'],
                name="Hlt1DownstreamBuScaPostScaled",
                line_type="hadron",
                enable_trigger=True,
                post_scaler=0.01,
                mva_busca_threshold=0.1),
            make_BuSca_line(  # BuSca HLT1 MuMu Line / Trigger enabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_secondary_vertices'],
                name="Hlt1DownstreamBuScaMuMuLine",
                line_type="muon",
                mva_busca_threshold=0.1,
                enable_trigger=True),
            make_BuSca_line(  # BuSca HLT1 ElEl Line / Trigger enabled
                reconstructed_objects[
                    'downstream_combined_hadronic_and_leptonic_secondary_vertices'],
                name="Hlt1DownstreamBuScaElElLine",
                line_type="electron",
                mva_busca_threshold=0.1,
                enable_trigger=True),
            make_downstream_two_track_ks_line(
                reconstructed_objects['downstream_tracks'],
                reconstructed_objects['downstream_secondary_vertices'],
                name='Hlt1DownstreamTwoTrackKs',
                minTrackPt_piKs=thresholds.
                DownstreamTwoTrackKs_minTrackPt_piKs,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
        ]
        if 'downstream_sv_pairs' in reconstructed_objects:
            lines += [
                # make_d02ksks_DDDD_line(
                #     reconstructed_objects['downstream_tracks'],
                #     reconstructed_objects['downstream_sv_pairs'],
                #     name='Hlt1D02KsKsDDDD',
                #     minTrackPt_piKs=450.0,
                #     minComboPt_Ks=1200.0,
                #     enable_tupling=enable_tupling),
                make_BuSca_line(  # BuSca HLT1 HH with PiPi mass hypo. with same sign reconstuction / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaPostScaledSameSign",
                    line_type="hadron",
                    post_scaler=0.01,
                    mva_busca_threshold=0.1,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 MuMu Line with same sign reconstuction / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaMuMuLineSameSign",
                    line_type="muon",
                    mva_busca_threshold=0.1,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 ElEl Line with same sign reconstuction / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaElElLineSameSign",
                    line_type="electron",
                    mva_busca_threshold=0.1,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 High Mass Line / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaHighMassLine",
                    line_type="monitoring",
                    histogram_ks_fd_min=500,
                    histogram_ks_fd_max=2500,
                    histogram_ks_fd_nbins=20,
                    histogram_ks_mass_min=1200,
                    histogram_ks_mass_max=50000,
                    histogram_ks_mass_nbins=50,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 High Mass Line with same sign reconstuction / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaHighMassLineSameSign",
                    line_type="monitoring",
                    histogram_ks_fd_min=500,
                    histogram_ks_fd_max=2500,
                    histogram_ks_fd_nbins=20,
                    histogram_ks_mass_min=1200,
                    histogram_ks_mass_max=50000,
                    histogram_ks_mass_nbins=50,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 MuMu High Mass Line / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaMuMuHighMassLine",
                    line_type="muon",
                    histogram_ks_fd_min=500,
                    histogram_ks_fd_max=2500,
                    histogram_ks_fd_nbins=20,
                    histogram_ks_mass_min=1200,
                    histogram_ks_mass_max=50000,
                    histogram_ks_mass_nbins=50,
                    enable_trigger=False),
                make_BuSca_line(  # BuSca HLT1 MuMu High Mass Line with same sign reconstuction / Trigger disabled
                    reconstructed_objects[
                        'downstream_combined_hadronic_and_leptonic_same_sign_secondary_vertices'],
                    name="Hlt1DownstreamBuScaMuMuHighMassLineSameSign",
                    line_type="muon",
                    histogram_ks_fd_min=500,
                    histogram_ks_fd_max=2500,
                    histogram_ks_fd_nbins=20,
                    histogram_ks_mass_min=1200,
                    histogram_ks_mass_max=50000,
                    histogram_ks_mass_nbins=50,
                    enable_trigger=False)
            ]
    if 'v0dd_hh_pairs' in reconstructed_objects:
        lines += [
            make_d2kshh_line(
                long_tracks,
                reconstructed_objects['v0dd_hh_pairs'],
                maxVertexChi2=10,
                pre_scaler=0.25,
                maxDOCA=2.5,
                minM_Ks=420.,
                maxM_Ks=540.,
                minTrackIP_Ks=0.2,
                minCTau_D0=0.5 * 0.1229,
                name="Hlt1DownstreamD2Kshh",
                enable_tupling=enable_tupling),
        ]

    if with_v0s:
        lines += [
            make_kstopipi_line(
                long_tracks, v0s, name="Hlt1KsToPiPi", post_scaler=0.001),
            make_kstopipi_line(
                long_tracks,
                v0s,
                name="Hlt1KsToPiPiDoubleMuonMisID",
                double_muon_misid=True,
                enable_monitoring=True),
            make_two_track_line_ks(
                long_tracks,
                v0s,
                name="Hlt1TwoTrackKs",
                minTrackPt_piKs=thresholds.TwoTrackKs_minTrackPt_piKs,
                minTrackIPChi2_Ks=thresholds.TwoTrackKs_minTrackIPChi2_piKs,
                maxEta_Ks=thresholds.TwoTrackKs_maxEta_Ks,
                min_combip=thresholds.TwoTrackKs_min_combip,
                minComboPt_Ks=thresholds.TwoTrackKs_minComboPt_Ks,
                enable_tupling=enable_tupling),
            make_two_ks_line(long_tracks, v0_pairs, name="Hlt1TwoKs"),
            make_lambda_ll_detached_track_line(
                lambda_track_from_c,
                name="Hlt1LambdaLLDetachedTrack",
                enable_tupling=enable_tupling),
            make_detached_xi_omega_lll_line(
                v0_twotrack_pairs,
                name="Hlt1XiOmegaLLL",
                enable_tupling=enable_tupling),
            make_d2kshh_line(
                long_tracks,
                v0_hh_pairs,
                name="Hlt1D2Kshh",
                enable_tupling=enable_tupling,
                minCTau_D0=0.5 * 0.1229)
        ]

    if with_muon:
        muonid = reconstructed_objects["muonID"]
        muon_nn_cuts = {
            'vloose':
            0.01,  #equivalent to Chi2Corr 2.4 provided PT cuts are loosened too
            'loose':
            0.03,  # equivalent to Chi2Corr 1.8 provided PT cuts are loosened too
            'displaced_soft_pt': 0.8,  #ad-hoc cut for the DP search
            'no_ip': 0.95,  # ad-hoc very tight for NoIP Line
        }
        lines += [
            make_single_high_pt_muon_line(
                long_tracks,
                long_track_particles,
                maxChi2Ndof=chi2_cuts.Hlt1SingleHighPtMuon_maxChi2Ndof,
                name="Hlt1SingleHighPtMuon",
                enable_tupling=enable_tupling,
                singleMinPt=thresholds.SingleHighPtLepton_pt),
            make_single_high_pt_muon_no_muid_line(
                long_tracks,
                long_track_particles,
                maxChi2Ndof=chi2_cuts.Hlt1SingleHighPtMuonNoMuID_maxChi2Ndof,
                name="Hlt1SingleHighPtMuonNoMuID",
                enable_tupling=enable_tupling,
                singleMinPt=thresholds.SingleHighPtLepton_pt_noMuonID),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                #maxChi2Corr=thresholds.DiMuonHighMass_maxCorrChi2,
                name="Hlt1DiMuonHighMass",
                enable_tupling=enable_tupling,
                minHighMassTrackPt=thresholds.DiMuonHighMass_pt,
                useMuonNN=True,
                minMuonNN=thresholds.DiMuonHighMass_NN),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDisplaced",
                minHighMassTrackPt=thresholds.DiMuonDisplaced_pt,
                minHighMassTrackP=3000.,
                minMass=0,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=thresholds.DiMuonDisplaced_ipchi2,
                enable_tupling=enable_tupling,
                minMuonNN=thresholds.DiMuonDisplaced_NN,
                useMuonNN=True,
            ),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDisplacedSoftPT",
                minHighMassTrackPt=0,
                minHighMassTrackP=3000.0,
                minMass=200,
                maxDoca=0.2,
                maxVertexChi2=9,
                minIPChi2=6,
                enable_tupling=enable_tupling,
                minMuonNN=thresholds.DiMuonDisplacedSoftPT_NN,
                useMuonNN=True,
                vetoSharedHits=True),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDisplacedSoftPT_SS",
                minHighMassTrackPt=0,
                minHighMassTrackP=3000.0,
                minMass=200,
                maxDoca=0.2,
                maxVertexChi2=9,
                minIPChi2=6,
                enable_tupling=enable_tupling,
                minMuonNN=thresholds.DiMuonDisplacedSoftPT_NN,
                useMuonNN=True,
                vetoSharedHits=True,
                oppositeSign=False,
                pre_scaler=0.01),
            make_di_muon_soft_line(
                long_tracks, dileptons, name="Hlt1DiMuonSoft"),
            make_track_muon_mva_line(
                long_tracks,
                long_track_particles,
                muonid,
                maxChi2Ndof=chi2_cuts.Hlt1TrackMuonMVA_maxChi2Ndof,
                maxChi2Corr=1.8,
                useMuonNN=True,
                minMuonNN=thresholds.TrackMuonMVA_NN,
                name="Hlt1TrackMuonMVA",
                enable_tupling=enable_tupling,
                alpha=thresholds.TrackMuonMVA_alpha),
            make_di_muon_no_ip_line(
                long_tracks,
                dileptons,
                muonid,
                maxVertexChi2=9,
                minNN=thresholds.DiMuonNoIP_NN,
                maxTrChi2=chi2_cuts.Hlt1DiMuonNoIP_maxTrChi2,
                enable_tupling=enable_tupling),
            make_di_muon_no_ip_line(
                long_tracks,
                dileptons,
                muonid,
                maxVertexChi2=9,
                minNN=thresholds.DiMuonNoIP_NN,
                maxTrChi2=chi2_cuts.Hlt1DiMuonNoIP_maxTrChi2,
                name="Hlt1DiMuonNoIP_SS",
                pre_scaler_hash_string="di_muon_no_ip_ss_line_pre",
                post_scaler_hash_string="di_muon_no_ip_ss_line_post",
                enable_tupling=enable_tupling,
                ss_on=True,
                post_scaler=.01),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonNoIPNorm",
                minHighMassTrackPt=0,
                minHighMassTrackP=3000.0,
                minMass=200,
                maxDoca=0.2,
                maxVertexChi2=9,
                minIPChi2=-1,
                enable_tupling=enable_tupling,
                minMuonNN=thresholds.DiMuonDisplacedSoftPT_NN,
                useMuonNN=True,
                vetoSharedHits=True,
                pre_scaler=0.001),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonNoIPNorm_SS",
                minHighMassTrackPt=0,
                minHighMassTrackP=3000.0,
                minMass=200,
                maxDoca=0.2,
                maxVertexChi2=9,
                minIPChi2=-1,
                enable_tupling=enable_tupling,
                minMuonNN=thresholds.DiMuonDisplacedSoftPT_NN,
                useMuonNN=True,
                vetoSharedHits=True,
                oppositeSign=False,
                pre_scaler=.001,
            ),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDrellYan_VLowMass",
                pre_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_post",
                minMass=2900.,
                maxMass=5000.,
                maxChi2Corr=1.8,
                minMuonNN=muon_nn_cuts['loose'],
                useMuonNN=False,
                minTrackP=10000,
                minTrackPt=1000,
                pre_scaler=.4,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDrellYan_VLowMass_SS",
                pre_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_pre",
                post_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_post",
                minMass=2900.,  # low enough to capture the J/psi
                maxMass=5000.,
                maxChi2Corr=1.8,
                minMuonNN=muon_nn_cuts['loose'],
                useMuonNN=False,
                minTrackP=10000,
                minTrackPt=1000,
                pre_scaler=.4,
                OppositeSign=False,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDrellYan",
                pre_scaler_hash_string="di_muon_drell_yan_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_line_post",
                minMass=5000.,
                minTrackP=12500,
                maxChi2Corr=2.4,
                minMuonNN=muon_nn_cuts['vloose'],
                useMuonNN=False,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonDrellYan_SS",
                pre_scaler_hash_string="di_muon_drell_yan_SS_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_SS_line_post",
                minMass=5000.,
                minTrackP=12500,
                maxChi2Corr=2.4,
                minMuonNN=muon_nn_cuts['vloose'],
                useMuonNN=False,
                OppositeSign=False,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_det_jpsitomumu_tap_line(
                long_tracks,
                dihadrons,
                name="Hlt1DetJpsiToMuMuPosTagLine",
                posTag=True,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_det_jpsitomumu_tap_line(
                long_tracks,
                dihadrons,
                name="Hlt1DetJpsiToMuMuNegTagLine",
                posTag=False,
                enable_monitoring=True,
                enable_tupling=enable_tupling)
        ]

    if with_calo:
        ecal_clusters = reconstructed_objects["ecal_clusters"]
        calo_matching_objects = reconstructed_objects["calo_matching_objects"]
        electronid_nn = reconstructed_objects["electronid_nn"]
        jets = reconstructed_objects["jets"]

        lines += [
            make_track_electron_mva_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                electronid_nn,
                maxChi2Ndof=chi2_cuts.Hlt1TrackElectronMVA_maxChi2Ndof,
                name="Hlt1TrackElectronMVA",
                alpha=thresholds.TrackElectronMVA_alpha,
                useNN=
                True,  #it uses it implicitely per the definition of isElectron
                minElectronNN=thresholds.TrackElectronMVA_NN,
                enable_tupling=enable_tupling),
            make_single_high_pt_electron_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                maxChi2Ndof=chi2_cuts.Hlt1SingleHighPtElectron_maxChi2Ndof,
                name="Hlt1SingleHighPtElectron",
                singleMinPt=thresholds.SingleHighPtLepton_pt,
                enable_tupling=enable_tupling),
            make_displaced_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                electronid_nn,
                useNN=
                True,  #it uses it implicitely per the definition of isElectron
                minElectronNN=thresholds.DiElectronDisplaced_NN,
                name="Hlt1DiElectronDisplaced",
                MinPT=thresholds.DiElectronDisplaced_pt,
                MinIPChi2=thresholds.DiElectronDisplaced_ipchi2,
                enable_tupling=enable_tupling),
            # make_single_high_et_line(
            #     velo_tracks, calo_matching_objects, name="Hlt1SingleHighEt"),
            make_diphotonhighmass_line(
                ecal_clusters,
                velo_tracks,
                pvs,
                name="Hlt1DiPhotonHighMass",
                enable_tupling=enable_tupling,
                minET=thresholds.DiPhotonHighMass_minET),
            make_pi02gammagamma_line(
                ecal_clusters,
                velo_tracks,
                pvs,
                name="Hlt1Pi02GammaGamma",
                pre_scaler_hash_string="p02gammagamma_line_pre",
                post_scaler_hash_string="p02gammagamma_line_post"),
            make_highmass_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                is_same_sign=True,
                pre_scaler=1.0,
                name="Hlt1DiElectronHighMass_SS"),
            make_highmass_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                is_same_sign=False,
                name="Hlt1DiElectronHighMass"),
            make_di_electron_soft_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                name="Hlt1DiElectronSoft"),
            make_cone_jet_line(
                jets,
                name="Hlt1ConeJet15GeV",
                min_pt=15000.,
                pre_scaler=0.001,
                pre_scaler_hash_string='cone_jet_15gev_line_pre',
                post_scaler_hash_string='cone_jet_15gev_line_post'),
            make_cone_jet_line(
                jets,
                name="Hlt1ConeJet30GeV",
                min_pt=30000.,
                pre_scaler=0.05,
                pre_scaler_hash_string='cone_jet_30gev_line_pre',
                post_scaler_hash_string='cone_jet_30gev_line_post'),
            make_cone_jet_line(
                jets,
                name="Hlt1ConeJet50GeV",
                min_pt=50000.,
                pre_scaler=0.1,
                pre_scaler_hash_string='cone_jet_50gev_line_pre',
                post_scaler_hash_string='cone_jet_50gev_line_post'),
            make_cone_jet_line(
                jets,
                name="Hlt1ConeJet100GeV",
                min_pt=100000.,
                pre_scaler=1,
                pre_scaler_hash_string='cone_jet_100gev_line_pre',
                post_scaler_hash_string='cone_jet_100gev_line_post'),
        ]

        for subSample in ["NoIP", "NoIPNorm", "Displaced"]:
            common_kwargs_low_mass_electron = {
                "minMass": 5,
                "maxMass": 300,
                "minPTprompt": 500.0,
                "minPTdisplaced": 0.0,
                "trackIPChi2Threshold": -1 if "NoIP" in subSample else
                4,  # it will only be picked up by the displaced line the NoIP (aka prompt) won't trigger this cut
                "selectPrompt": "NoIP" in subSample,
                "useNN": True,
                "nnCut": 0.96 if subSample == "NoIP" else 0.73,
                "enable_monitoring": True,
                "enable_tupling": enable_tupling
            }
            lines.append(
                make_lowmass_dielectron_line(
                    long_tracks,
                    dileptons,
                    electronid_nn,
                    calo_matching_objects,
                    **common_kwargs_low_mass_electron,
                    name="Hlt1DiElectronLowMass_{}".format(subSample),
                    pre_scaler_hash_string=
                    "Hlt1DiElectronLowMass_massSlice_{}_pre".format(subSample),
                    post_scaler=0.02 if subSample == "NoIPNorm" else 1,
                ))
            lines.append(
                make_lowmass_dielectron_line(
                    long_tracks,
                    dileptons,
                    electronid_nn,
                    calo_matching_objects,
                    **common_kwargs_low_mass_electron,
                    is_same_sign=True,
                    name="Hlt1DiElectronLowMass_SS_{}".format(subSample),
                    pre_scaler_hash_string=
                    "Hlt1DiElectronLowMass_massSlice_SS_{}_pre".format(
                        subSample),
                    post_scaler=0.02,
                ))
    return [line_maker(line) for line in lines]


def odin_monitoring_lines(with_lumi, lumiline_name, lumilinefull_name,
                          odin_err_filter, velo_closed_filter):
    lines = []
    if with_lumi:
        odin_lumi_event = make_event_type(event_type='Lumi')
        with line_maker.bind(prefilter=odin_err_filter + [odin_lumi_event]):
            lines += [
                line_maker(
                    make_passthrough_line(name=lumiline_name, pre_scaler=1.))
            ]

        odin_orbit = make_odin_orbit(
            odin_orbit_modulo=30, odin_orbit_remainder=1)
        with line_maker.bind(
                prefilter=odin_err_filter + [odin_lumi_event, odin_orbit]):
            lines += [
                line_maker(
                    make_passthrough_line(
                        name=lumilinefull_name, pre_scaler=1.))
            ]

    with line_maker.bind(prefilter=odin_err_filter):
        lines += [line_maker(make_odin_calib_line(name="Hlt1ODINCalib"))]

    ee_far_from_activity = make_event_type(event_type="ee_far_from_activity")
    with line_maker.bind(prefilter=odin_err_filter + velo_closed_filter +
                         [ee_far_from_activity]):
        lines += [
            line_maker(
                make_passthrough_line(
                    name="Hlt1ODINeeFarFromActivity", pre_scaler=1.))
        ]

    return lines


def alignment_monitoring_lines(reconstructed_objects,
                               prefilters_bx,
                               prefilters_odin_err,
                               thresholds,
                               chi2_cuts,
                               with_muon=True):

    velo_tracks = reconstructed_objects["velo_tracks"]
    material_interaction_tracks = reconstructed_objects[
        "material_interaction_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    velo_states = reconstructed_objects["velo_states"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]
    dstars = reconstructed_objects["dstars"]
    muon_stubs = reconstructed_objects["muon_stubs"]

    lines = [
        make_rich_1_line(
            long_tracks,
            long_track_particles,
            maxTrChi2=chi2_cuts.Hlt1RICH1Alignment_maxTrChi2,
            name="Hlt1RICH1Alignment"),
        make_rich_2_line(
            long_tracks,
            long_track_particles,
            maxTrChi2=chi2_cuts.Hlt1RICH2Alignment_maxTrChi2,
            name="Hlt1RICH2Alignment"),
        make_d2kpi_align_line(
            long_tracks, dihadrons, name="Hlt1D2KPiAlignment"),
        make_dst_line(dstars, name="Hlt1Dst2D0PiAlignment"),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=300,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeedsDownstreamz",
            pre_scaler=5e-4),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=700,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeeds_DWFS",
            pre_scaler=0.1)
    ]

    if with_muon:
        muonid = reconstructed_objects["muonID"]
        lines += [
            make_di_muon_mass_align_line(
                long_tracks,
                dileptons,
                muonid,
                name="Hlt1DiMuonJpsiMassAlignment"),
            make_one_muon_track_line(
                muon_stubs["consolidated_muon_tracks"],
                muon_stubs["dev_muon_tracks_offsets"],
                muon_stubs["host_muon_total_number_of_tracks"],
                name="Hlt1OneMuonTrackLine",
                post_scaler=6e-5),
            make_di_muon_mass_align_line(
                long_tracks,
                dileptons,
                muonid,
                minHighMassTrackPt=1800.,
                minHighMassTrackP=20000.,
                name="Hlt1UpsilonAlignment",
                minMass=8000.,
                maxMass=12000.,
                minFdChi2=-1.,
                minIP=-1.,
                minDira=0.9),
        ]

    with line_maker.bind(prefilter=prefilters_bx):
        lines = [line_maker(line) for line in lines]

    with line_maker.bind(prefilter=prefilters_odin_err):
        lines += [
            line_maker(
                make_velo_micro_bias_line(
                    velo_tracks,
                    name="Hlt1VeloMicroBias",
                    pre_scaler=1.,
                    post_scaler=1.e-3))
        ]

    return lines


@configurable
def default_SMOG2_lines(reconstructed_objects,
                        chi2_cuts,
                        with_muon=True,
                        with_v0s=True,
                        min_z=-537.5,
                        max_z=-337.5,
                        enable_tupling=False):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    prompt_dihadrons = reconstructed_objects[
        "prompt_dihadron_secondary_vertices"]
    v0s = reconstructed_objects["v0_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]

    lines = [
        make_SMOG2_ditrack_line(
            dihadrons,
            m1=139.57,
            m2=493.68,
            mMother=1864.83,
            mWindow=100.,
            min_z=min_z,
            max_z=max_z,
            minEitherTrackPt=800.,
            minTrackPt=500.,
            minTrackIPCHI2=7.,
            minFDCHI2=25.,
            maxTrackChi2Ndf=chi2_cuts.Hlt1_SMOG2_DiTrack_maxTrackChi2Ndf,
            name="Hlt1SMOG2D2Kpi",
            pre_scaler=1.,
            enable_tupling=enable_tupling),
        make_SMOG2_ditrack_line(
            prompt_dihadrons,
            m1=938.27,
            m2=938.27,
            mMother=3000.,
            mWindow=200.,
            min_z=min_z,
            max_z=max_z,
            minTrackIPCHI2=0.,
            maxTrackIPCHI2=5.,
            maxFDCHI2=20.,
            maxTrackChi2Ndf=chi2_cuts.Hlt1_SMOG2_DiTrack_maxTrackChi2Ndf,
            minTrackP=25000.,
            minTrackPt=1000.,
            minEitherTrackPt=1200.,
            name="Hlt1SMOG2etacTopp",
            pre_scaler=1.,
            enable_tupling=enable_tupling),
        make_SMOG2_kstopipi_line(
            dihadrons,
            min_z=min_z,
            max_z=max_z,
            name="Hlt1SMOG2KsTopipi",
            minTrackPt=250.,
            minMass=450.,
            pre_scaler=0.3,
            enable_tupling=enable_tupling),
        make_SMOG2_ditrack_line(
            dihadrons,
            minTrackPt=500.,
            minEitherTrackPt=800.,
            min_z=min_z,
            max_z=max_z,
            minMdipion=1300,
            minFDCHI2=25.,
            maxTrackChi2Ndf=chi2_cuts.Hlt1_SMOG2_DiTrack_maxTrackChi2Ndf,
            minTrackIPCHI2=7.,
            name="Hlt1SMOG22BodyGeneric",
            enable_monitoring=False,
            enable_tupling=enable_tupling,
            pre_scaler=0.3),
        make_SMOG2_ditrack_line(
            prompt_dihadrons,
            minTrackPt=400.,
            minEitherTrackPt=400.,
            min_z=min_z,
            max_z=max_z,
            minTrackIPCHI2=0.,
            maxTrackChi2Ndf=chi2_cuts.Hlt1_SMOG2_DiTrack_maxTrackChi2Ndf,
            enable_monitoring=False,
            enable_tupling=enable_tupling,
            name="Hlt1SMOG22BodyGenericPrompt",
            pre_scaler=0.01),
        make_SMOG2_singletrack_line(
            long_tracks,
            long_track_particles,
            maxChi2Ndof=chi2_cuts.Hlt1SMOG2SingleTrackVeryHighPt_maxChi2Ndof,
            name="Hlt1SMOG2SingleTrackVeryHighPt",
            minPt=5000.,
            pre_scaler=1,
            min_z=min_z,
            max_z=max_z),
        make_SMOG2_singletrack_line(
            long_tracks,
            long_track_particles,
            maxChi2Ndof=chi2_cuts.Hlt1SMOG2SingleTrackHighPt_maxChi2Ndof,
            name="Hlt1SMOG2SingleTrackHighPt",
            minPt=3000.,
            pre_scaler=0.1,
            min_z=min_z,
            max_z=max_z)
    ]

    if with_muon:
        muonid = reconstructed_objects["muonID"]
        lines += [
            make_SMOG2_dimuon_highmass_line(
                dileptons,
                long_tracks,
                muonid,
                maxTrackChi2Ndf=chi2_cuts.Hlt1SMOG2DiMuonHighMass_maxTrackChi2,
                maxChi2Corr=9999.,
                enable_tupling=enable_tupling,
                name="Hlt1SMOG2DiMuonHighMass"),
            make_SMOG2_single_muon_line(
                long_tracks,
                long_track_particles,
                muonid,
                maxChi2Ndof=chi2_cuts.Hlt1SMOG2SingleMuon_maxChi2Ndof,
                maxChi2Corr=1.8,
                useMuonNN=False,
                MinPt=1250,
                name="Hlt1SMOG2SingleMuon",
                pre_scaler=1.),
            make_SMOG2_dimuon_displaced_line(
                dileptons,
                long_tracks,
                muonid,
                maxChi2Corr=1.3,
                useMuonNN=False,
                minFDCHI2=100.,
                name="Hlt1SMOG2DisplacedDiMuon"),
            make_SMOG2_jpsitomumu_tap_line(
                prompt_dihadrons,
                long_tracks,
                muonid,
                maxTrackChi2Ndf=chi2_cuts.
                Hlt1SMOG2JPsiToMuMuTaP_maxTrackChi2Ndf,
                posTag=True,
                maxChi2Corr=1.8,
                useMuonNN=False,
                enable_tupling=enable_tupling,
                name="Hlt1SMOG2JPsiToMuMuTaP_PosTag"),
            make_SMOG2_jpsitomumu_tap_line(
                prompt_dihadrons,
                long_tracks,
                muonid,
                maxTrackChi2Ndf=chi2_cuts.
                Hlt1SMOG2JPsiToMuMuTaP_maxTrackChi2Ndf,
                posTag=False,
                maxChi2Corr=1.8,
                useMuonNN=False,
                enable_tupling=enable_tupling,
                name="Hlt1SMOG2JPsiToMuMuTaP_NegTag")
        ]

    if with_v0s:
        lines += [
            make_lambda2ppi_line(
                v0s,
                name="Hlt1SMOG2L0Toppi",
                minPVZ=min_z,
                maxPVZ=max_z,
                minVZ=min_z,
                maxVtxChi2=10.,
                minDIRA=0.99985,
                minpipchi2=16.,
                minpiipchi2=42.,
                minpipt=150.,
                enable_monitoring=True,
                enable_tupling=enable_tupling)
        ]

    return [line_maker(line) for line in lines]


@configurable
def default_bgi_activity_lines(pvs,
                               velo_states,
                               decoded_velo,
                               decoded_calo,
                               enableBGI_full=False,
                               PbPb_collision=False,
                               prefilter=[]):
    """
    Primary vertex lines for various bunch crossing types composed from
    new PV filters and beam crossing lines.
    """

    mm = 1.0  # from SystemOfUnits.h
    max_cyl_rad_sq = (3 * mm)**2
    bx_BB = make_bxtype(bx_type=3)
    bx_NoBB = make_invert_event_list(bx_BB, name="BX_NoBeamBeam")
    pvs_z_all = make_checkCylPV(
        pvs,
        name="BGIPVsCylAll",
        min_vtx_z=-2000.,
        max_vtz_z=2000.,
        max_vtx_rho_sq=max_cyl_rad_sq,
        min_vtx_nTracks=10.)
    lines = []

    # Alternate version based on track beamline states
    velo_states_z_all = make_checkPseudoPV(
        velo_states,
        name="BGIPseudoPVsAll",
        min_state_z=-2000.,
        max_state_z=2000.,
        max_state_rho_sq=max_cyl_rad_sq,
        min_local_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsNoBeam",
                beam_crossing_type=0,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, velo_states_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsBeamOne",
                beam_crossing_type=1,
                pre_scaler=1. if enableBGI_full else 1e-2,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, velo_states_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsBeamTwo",
                beam_crossing_type=2,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, velo_states_z_all])
    ]

    velo_states_z_up = make_checkPseudoPV(
        velo_states,
        name="BGIPseudoPVsUp",
        min_state_z=-2000.,
        max_state_z=-250.,
        max_state_rho_sq=max_cyl_rad_sq,
        min_local_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsUpBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1. if enableBGI_full else 1e-3,
                post_scaler=1.),
            prefilter=prefilter + [velo_states_z_up])
    ]

    velo_states_z_down = make_checkPseudoPV(
        velo_states,
        name="BGIPseudoPVsDown",
        min_state_z=250.,
        max_state_z=2000.,
        max_state_rho_sq=max_cyl_rad_sq,
        min_local_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsDownBeamBeam",
                beam_crossing_type=3,
                pre_scaler=0.05,
                post_scaler=1.),
            prefilter=prefilter + [velo_states_z_down])
    ]

    velo_states_z_ir = make_checkPseudoPV(
        velo_states,
        name="BGIPseudoPVsIR",
        min_state_z=-250.,
        max_state_z=250.,
        max_state_rho_sq=max_cyl_rad_sq,
        min_local_nTracks=28. if not PbPb_collision else 10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsIRBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1. if enableBGI_full else 4e-5,
                post_scaler=1.),
            prefilter=prefilter + [velo_states_z_ir])
    ]

    if not enableBGI_full:
        return lines

    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylNoBeam",
                beam_crossing_type=0,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylBeamOne",
                beam_crossing_type=1,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all]),
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylBeamTwo",
                beam_crossing_type=2,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [bx_NoBB, pvs_z_all])
    ]

    pvs_z_up = make_checkCylPV(
        pvs,
        name="BGIPVsCylUp",
        min_vtx_z=-2000.,
        max_vtz_z=-250.,
        max_vtx_rho_sq=max_cyl_rad_sq,
        min_vtx_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylUpBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_up])
    ]

    pvs_z_down = make_checkCylPV(
        pvs,
        name="BGIPVsCylDown",
        min_vtx_z=250.,
        max_vtz_z=2000.,
        max_vtx_rho_sq=max_cyl_rad_sq,
        min_vtx_nTracks=10.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylDownBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_down])
    ]

    pvs_z_ir = make_checkCylPV(
        pvs,
        name="BGIPVsCylIR",
        min_vtx_z=-250.,
        max_vtz_z=250.,
        max_vtx_rho_sq=max_cyl_rad_sq,
        min_vtx_nTracks=28.)
    return lines


def setup_hlt1_node(enablePhysics=True,
                    withMCChecking=False,
                    EnableGEC=True,
                    DisableLinesDuringVPClosing=True,
                    withSMOG2=True,
                    enableRateValidator=True,
                    with_ut=True,
                    with_lumi=True,
                    with_odin_filter=True,
                    with_calo=True,
                    with_muon=True,
                    with_v0s=True,
                    with_rich=False,
                    with_AC_split=False,
                    enableBGI=True,
                    velo_open=False,
                    enableDownstream=False,
                    tracking_type=TrackingType.FORWARD,
                    threshold_settings=get_thresholds("default"),
                    tae_passthrough=True,
                    tae_activity=False,
                    enableTupling=False,
                    data_quality=False,
                    with_fullKF=False,
                    passthrough_pre_scaler=0.0001,
                    enabled_lines=[r'.*?'],
                    disabled_lines=[],
                    user_hooks=False):

    if with_fullKF:
        from AllenConf.secondary_vertex_reconstruction import ParKF_cuts as chi2_cuts
    else:
        from AllenConf.secondary_vertex_reconstruction import Velo_only_cuts as chi2_cuts

    hlt1_config = {}
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(
        with_calo=with_calo,
        with_ut=with_ut,
        with_muon=with_muon,
        enableDownstream=enableDownstream,
        tracking_type=tracking_type,
        velo_open=velo_open,
        with_AC_split=with_AC_split,
        with_rich=with_rich,
        with_fullKF=with_fullKF,
        track_max_chi2ndof=chi2_cuts.SV_track_max_chi2ndof)

    hlt1_config['reconstruction'] = reconstructed_objects

    gec = [
        make_gec(
            count_ut=False,
            count_velo=True,
            max_scifi_clusters=20000,
            max_velo_clusters=35000)
    ] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []
    beam_beam_filter = [make_bxtype(bx_type=3)]
    velo_open_event = make_event_type(event_type="VeloOpen")
    velo_closed = [
        make_event_type(
            name="ODIN_EvenType_VeloClosed",
            event_type="VeloOpen",
            invert=True)
    ] if DisableLinesDuringVPClosing else []
    prefilters = odin_err_filter + beam_beam_filter + velo_closed + gec

    physics_lines = []
    if enablePhysics:
        with line_maker.bind(prefilter=prefilters):
            physics_lines += default_physics_lines(
                reconstructed_objects, with_calo, with_muon, with_v0s,
                threshold_settings, enableTupling, chi2_cuts)

    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"

    monitoring_lines = odin_monitoring_lines(with_lumi, lumiline_name,
                                             lumilinefull_name,
                                             odin_err_filter, velo_closed)

    with line_maker.bind(prefilter=odin_err_filter):
        physics_lines += [
            line_maker(
                make_passthrough_line(pre_scaler=passthrough_pre_scaler))
        ]

    if tae_passthrough:
        if tae_activity:

            tae_activity_filter = make_tae_activity_filter(
                reconstructed_objects["long_tracks"],
                reconstructed_objects["velo_tracks"])

            tae_filters = CompositeNode(
                "taefilter_node",
                [tae_activity_filter, tae_filter()],
                NodeLogic.LAZY_AND,
                force_order=True)
        else:
            tae_filters = tae_filter()

        with line_maker.bind(prefilter=odin_err_filter + [tae_filters]):
            physics_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1TAEPassthrough", pre_scaler=1))
            ]

    with line_maker.bind(prefilter=[sd_error_filter()]):
        monitoring_lines += [
            line_maker(
                make_passthrough_line(name="Hlt1ErrorBank", pre_scaler=0.0001))
        ]

    with line_maker.bind(prefilter=odin_err_filter + [velo_open_event]):
        monitoring_lines += [
            line_maker(
                make_velo_micro_bias_line(
                    reconstructed_objects["velo_tracks"],
                    name="Hlt1VeloMicroBiasVeloClosing",
                    post_scaler=3.e-3))
        ]

    if EnableGEC:
        with line_maker.bind(prefilter=odin_err_filter + gec):
            physics_lines += [
                line_maker(make_passthrough_line(name="Hlt1GECPassthrough"))
            ]

    if enableBGI:
        bgi_prefilters = odin_err_filter + velo_closed + gec
        physics_lines += default_bgi_activity_lines(
            reconstructed_objects["pvs"],
            reconstructed_objects["velo_states"],
            decode_velo(),
            decode_calo(),
            prefilter=bgi_prefilters)

    monitoring_lines += alignment_monitoring_lines(
        reconstructed_objects, prefilters, odin_err_filter, threshold_settings,
        chi2_cuts, with_muon)

    bx_BE = make_bxtype(bx_type=1)
    with line_maker.bind(
            prefilter=odin_err_filter + [bx_BE] + velo_closed + gec):
        monitoring_lines += [
            line_maker(
                make_beam_gas_line(
                    reconstructed_objects["velo_tracks"],
                    reconstructed_objects["velo_states"],
                    beam_crossing_type=1,
                    name="Hlt1BeamGas")),
        ]

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:
        SMOG2_prefilters, SMOG2_lines = [], []
        SMOG2_prefilters += velo_closed
        with line_maker.bind(
                prefilter=odin_err_filter + [bx_BE] + velo_closed):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1SMOG2BENoBias", pre_scaler=3.e-4))
            ]

        if with_calo:
            lowMult_5 = make_lowmult(
                reconstructed_objects['velo_tracks'],
                reconstructed_objects["ecal_clusters"],
                name="LowMult_5",
                minTracks=1,
                maxTracks=5)
            with line_maker.bind(
                    prefilter=odin_err_filter + velo_closed + [lowMult_5]):
                SMOG2_lines += [
                    line_maker(
                        make_passthrough_line(
                            name="Hlt1SMOG2PassThroughLowMult5",
                            pre_scaler=0.1))
                ]

            lowMultElectrons = make_lowmult(
                reconstructed_objects['velo_tracks'],
                reconstructed_objects["ecal_clusters"],
                name="LowMultElectrons",
                minTracks=1,
                maxTracks=3,
                min_ecal_clusters=1,
                max_ecal_clusters=10)
            with line_maker.bind(prefilter=odin_err_filter + [bx_BE] +
                                 velo_closed + [lowMultElectrons]):
                SMOG2_lines += [
                    line_maker(
                        make_passthrough_line(
                            name="Hlt1SMOG2BELowMultElectrons",
                            pre_scaler=0.1))
                ]

        if EnableGEC:
            SMOG2_prefilters += gec

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_SMOG2_minimum_bias_line(
                        reconstructed_objects["velo_tracks"],
                        reconstructed_objects["velo_states"],
                        name="Hlt1SMOG2MinimumBias",
                        pre_scaler=0.00003))
            ]

        SMOG2_prefilters += [
            make_checkPV(reconstructed_objects['pvs'], name='check_SMOG2_PV')
        ]

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1PassthroughPVinSMOG2", pre_scaler=0.00006))
            ]

            SMOG2_lines += default_SMOG2_lines(
                reconstructed_objects,
                chi2_cuts,
                with_muon,
                with_v0s,
                enable_tupling=enableTupling)

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    line_algorithms = [
        line for line in line_algorithms if any(
            re.match(r, line.name) for r in enabled_lines)
    ]
    line_algorithms = [
        line for line in line_algorithms
        if not any(re.match(r, line.name) for r in disabled_lines)
    ]

    persistency_node, persistency_algorithms = make_persistency(
        line_algorithms)

    hlt1_node = CompositeNode(
        "Allen", [lines, persistency_node],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config.update(persistency_algorithms)

    if with_lumi:
        lumi_reco = lumi_reconstruction(
            gather_selections=hlt1_config['gather_selections'],
            lumiline_name=lumiline_name,
            lumilinefull_name=lumilinefull_name,
            with_muon=with_muon,
            velo_open=velo_open)

        lumi_node = CompositeNode(
            "AllenLumiNode",
            lumi_reco["algorithms"],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        lumi_with_prefilter = CompositeNode(
            "LumiWithPrefilter",
            odin_err_filter + velo_closed + [lumi_node],
            NodeLogic.LAZY_AND,
            force_order=True)

        hlt1_config['lumi_reconstruction'] = lumi_reco
        hlt1_config['lumi_node'] = lumi_with_prefilter

        hlt1_node = CompositeNode(
            "AllenWithLumi", [hlt1_node, lumi_with_prefilter],
            NodeLogic.NONLAZY_AND,
            force_order=False)

    if with_rich:
        hlt1_node = CompositeNode(
            "AllenWithRich", [
                hlt1_node,
                reconstructed_objects["decoded_rich"]["dev_smart_ids"].producer
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)

    if enableRateValidator:
        hlt1_node = CompositeNode(
            "AllenRateValidation", [
                hlt1_node,
                rate_validation(lines=line_algorithms),
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)
    if user_hooks != False: hlt1_node = user_hooks(hlt1_node)

    if data_quality:
        # Forward reconstructed long tracks are needed for that module
        # Matching method is already used in reconstructed_objects
        reconstructed_objects_forward = hlt1_reconstruction(
            "ODQV_forward",
            with_calo=with_calo,
            with_ut=with_ut,
            with_muon=with_muon,
            tracking_type=TrackingType.FORWARD)
        node = make_dq_node(
            reconstructed_objects,
            reconstructed_objects_forward,
            prefilters=beam_beam_filter)
        return node

    if not withMCChecking:
        hlt1_config['control_flow_node'] = hlt1_node
    else:
        validation_node = validator_node(
            reconstructed_objects, line_algorithms,
            includes_matching(tracking_type), with_ut, with_muon,
            with_AC_split, with_fullKF, prefilters)
        hlt1_config['validator_node'] = validation_node

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)
        hlt1_config['control_flow_node'] = node

    return hlt1_config
