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
from AllenConf.utils import (line_maker, make_gec, make_checkPV, make_lowmult,
                             make_checkCylPV, make_checkPseudoPV,
                             make_invert_event_list, sd_error_filter,
                             make_tae_activity_filter)
from AllenConf.odin import make_bxtype, odin_error_filter, tae_filter, make_event_type
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
from AllenConf.hlt1_photon_lines import make_diphotonhighmass_line
from AllenConf.persistency import make_persistency
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.plume_reconstruction import decode_plume
from AllenConf.enum_types import TrackingType, includes_matching
from AllenConf.thresholds import get_thresholds


def default_physics_lines(reconstructed_objects, with_calo, with_muon,
                          with_v0s, thresholds, enable_tupling):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    pvs = reconstructed_objects["pvs"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]
    v0s = reconstructed_objects["v0_secondary_vertices"]
    v0_track_pairs = reconstructed_objects["v0_sv_track_pairs"]
    v0_pairs = reconstructed_objects["v0_pairs"]
    muon_stubs = reconstructed_objects["muon_stubs"]

    lines = [
        make_track_mva_line(
            long_tracks,
            long_track_particles,
            name="Hlt1TrackMVA",
            enable_tupling=enable_tupling,
            alpha=thresholds.alpha),
        make_two_track_mva_line(
            long_tracks,
            dihadrons,
            name="Hlt1TwoTrackMVA",
            enable_tupling=enable_tupling,
            minMVA=thresholds.minMVA),
        make_d2kk_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2KK",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.charm_track_ip,
            charm_track_pt=thresholds.charm_track_pt),
        make_d2kpi_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2KPi",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.charm_track_ip,
            charm_track_pt=thresholds.charm_track_pt),
        make_d2pipi_line(
            long_tracks,
            dihadrons,
            name="Hlt1D2PiPi",
            enable_tupling=enable_tupling,
            charm_track_ip=thresholds.charm_track_ip,
            charm_track_pt=thresholds.charm_track_pt)
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
                minTrackPt_piKs=thresholds.minTrackPt_piKs,
                minTrackIPChi2_Ks=thresholds.minTrackIPChi2_piKs,
                maxEta_Ks=thresholds.minEta_Ks,
                min_combip=thresholds.min_combip,
                minComboPt_Ks=thresholds.minComboPt_Ks,
                enable_tupling=enable_tupling),
            make_two_ks_line(long_tracks, v0_pairs, name="Hlt1TwoKs"),
            make_lambda2ppi_line(
                v0s, name="Hlt1L02PPi", enable_tupling=enable_tupling),
            make_lambda_ll_detached_track_line(
                v0_track_pairs,
                name="Hlt1LambdaLLDetachedTrack",
                enable_tupling=enable_tupling),
            make_xi_omega_lll_line(
                v0_track_pairs,
                name="Hlt1XiOmegaLLL",
                enable_tupling=enable_tupling),
        ]

    if with_muon:
        lines += [
            make_one_muon_track_line(
                muon_stubs["dev_muon_number_of_tracks"],
                muon_stubs["consolidated_muon_tracks"],
                muon_stubs["dev_output_buffer"],
                muon_stubs["host_total_sum_holder"],
                name="Hlt1OneMuonTrackLine",
                post_scaler=0.001),
            make_single_high_pt_muon_line(
                long_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuon",
                enable_tupling=enable_tupling,
                singleMinPt=thresholds.singleMinPt),
            make_single_high_pt_muon_no_muid_line(
                long_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuonNoMuID",
                singleMinPt=thresholds.singleMinPt_noMuonID),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonHighMass",
                enable_tupling=enable_tupling,
                minHighMassTrackPt=thresholds.highmass_dimuon_pt),
            make_di_muon_mass_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonDisplaced",
                minHighMassTrackPt=thresholds.displaced_dimuon_pt,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=thresholds.displaced_dimuon_ipchi2,
                enable_tupling=enable_tupling),
            make_di_muon_soft_line(
                long_tracks, dileptons, name="Hlt1DiMuonSoft"),
            make_track_muon_mva_line(
                long_tracks,
                long_track_particles,
                name="Hlt1TrackMuonMVA",
                enable_tupling=enable_tupling,
                alpha=thresholds.alpha_muon),
            make_di_muon_no_ip_line(long_tracks, dileptons),
            make_di_muon_no_ip_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonNoIP_ss",
                pre_scaler_hash_string="di_muon_no_ip_ss_line_pre",
                post_scaler_hash_string="di_muon_no_ip_ss_line_post",
                ss_on=True,
                post_scaler=.1),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonDrellYan_VLowMass",
                pre_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_post",
                minMass=2900.,
                maxMass=5000.,
                pre_scaler=.2,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonDrellYan_VLowMass_SS",
                pre_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_pre",
                post_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_post",
                minMass=2900.,  # low enough to capture the J/psi
                maxMass=5000.,
                pre_scaler=.2,
                OppositeSign=False,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonDrellYan",
                pre_scaler_hash_string="di_muon_drell_yan_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_line_post",
                minMass=5000.,
                enable_monitoring=True,
                enable_tupling=enable_tupling),
            make_di_muon_drell_yan_line(
                long_tracks,
                dileptons,
                name="Hlt1DiMuonDrellYan_SS",
                pre_scaler_hash_string="di_muon_drell_yan_SS_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_SS_line_post",
                minMass=5000.,
                OppositeSign=False,
                enable_monitoring=True,
                enable_tupling=enable_tupling)
        ]

    if with_calo:
        ecal_clusters = reconstructed_objects["ecal_clusters"]
        calo_matching_objects = reconstructed_objects["calo_matching_objects"]
        electronid_nn = reconstructed_objects["electronid_nn"]
        lines += [
            make_track_electron_mva_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                name="Hlt1TrackElectronMVA",
                alpha=thresholds.alpha_electron,
                enable_tupling=enable_tupling),
            make_single_high_pt_electron_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                name="Hlt1SingleHighPtElectron",
                singleMinPt=thresholds.singleMinPt,
                enable_tupling=enable_tupling),
            make_displaced_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                name="Hlt1DisplacedDielectron",
                MinPT=thresholds.displaced_dielectron_pt,
                MinIPChi2=thresholds.displaced_dielectron_ipchi2,
                enable_tupling=enable_tupling),
            # make_single_high_et_line(
            #     velo_tracks, calo_matching_objects, name="Hlt1SingleHighEt"),
            make_diphotonhighmass_line(
                ecal_clusters,
                velo_tracks,
                pvs,
                name="Hlt1DiPhotonHighMass",
                enable_tupling=enable_tupling,
                minET=thresholds.diphoton_minET),
            make_pi02gammagamma_line(
                ecal_clusters,
                velo_tracks,
                pvs,
                name="Hlt1Pi02GammaGamma",
                pre_scaler_hash_string="p02gammagamma_line_pre",
                post_scaler_hash_string="p02gammagamma_line_post",
                pre_scaler=0.005),
            make_highmass_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                is_same_sign=True,
                pre_scaler=1.0,
                name="Hlt1DiElectronHighMass_SameSign"),
            make_highmass_dielectron_line(
                long_tracks,
                dileptons,
                calo_matching_objects,
                is_same_sign=False,
                name="Hlt1DiElectronHighMass"),
        ]

        line_slices_mass = {
            "1": (5., 30.),
            "2": (30., 100.),
            "3": (100., 200.),
            "4": (200., 300.)
        }
        line_slices_postscales = {"1": 1, "2": 1, "3": 0.3, "4": 0.3}
        for subSample in ["prompt", "displaced"]:
            for label, limits in line_slices_mass.items():
                postscale_os = line_slices_postscales[
                    label] if subSample == "prompt" else 1.0
                nnCut = 0.90
                lines.append(
                    make_lowmass_dielectron_line(
                        long_tracks,
                        dileptons,
                        electronid_nn,
                        calo_matching_objects,
                        minMass=limits[0],
                        maxMass=limits[1],
                        minPTprompt=500.,
                        minPTdisplaced=0.,
                        trackIPChi2Threshold=2,
                        selectPrompt=True if subSample == "prompt" else False,
                        useNN=True,
                        nnCut=nnCut,
                        name="Hlt1LowMassDiElectron_massSlice{}_{}".format(
                            label, subSample),
                        pre_scaler_hash_string=
                        "lowmass_dielectronNN_massSlice{}_{}_pre".format(
                            label, subSample),
                        post_scaler=postscale_os))
                lines.append(
                    make_lowmass_dielectron_line(
                        long_tracks,
                        dileptons,
                        electronid_nn,
                        calo_matching_objects,
                        is_same_sign=True,
                        minMass=limits[0],
                        maxMass=limits[1],
                        minPTprompt=500.,
                        minPTdisplaced=0.,
                        trackIPChi2Threshold=2,
                        selectPrompt=True if subSample == "prompt" else False,
                        useNN=True,
                        nnCut=nnCut,
                        name="Hlt1LowMassDiElectron_SS_massSlice{}_{}".format(
                            label, subSample),
                        pre_scaler_hash_string=
                        "lowmass_dielectron_SS_massSlice{}_{}_pre".format(
                            label, subSample),
                        post_scaler=0.02,
                        post_scaler_hash_string=
                        "lowmass_dielectron_SS_massSlice{}_{}_post".format(
                            label, subSample)))

    return [line_maker(line) for line in lines]


def odin_monitoring_lines(with_lumi, lumiline_name, lumilinefull_name):
    lines = []
    if with_lumi:
        lines.append(
            line_maker(
                make_odin_event_type_line(
                    name=lumiline_name, odin_event_type='Lumi')))
        lines.append(
            line_maker(
                make_odin_event_and_orbit_line(
                    name=lumilinefull_name,
                    odin_event_type='Lumi',
                    odin_orbit_modulo=30,
                    odin_orbit_remainder=1)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                odin_event_type="NoBias", pre_scaler=0.0001)))
    return lines


def alignment_monitoring_lines(reconstructed_objects,
                               prefilters_bx,
                               prefilters_no_bx,
                               with_muon=True):

    velo_tracks = reconstructed_objects["velo_tracks"]
    material_interaction_tracks = reconstructed_objects[
        "material_interaction_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    velo_states = reconstructed_objects["velo_states"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]

    lines = [
        make_velo_micro_bias_line(velo_tracks, name="Hlt1VeloMicroBias"),
        make_rich_1_line(
            long_tracks, long_track_particles, name="Hlt1RICH1Alignment"),
        make_rich_2_line(
            long_tracks, long_track_particles, name="Hlt1RICH2Alignment"),
        make_d2kpi_line(long_tracks, dihadrons, name="Hlt1D2KPiAlignment"),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=300,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeedsDownstreamz",
            post_scaler=0.02),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=700,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeeds_DWFS")
    ]

    if with_muon:
        lines += [
            make_di_muon_mass_align_line(
                long_tracks, dileptons, name="Hlt1DiMuonHighMassAlignment"),
            make_di_muon_mass_align_line(
                long_tracks,
                dileptons,
                minMass=2500.,
                name="Hlt1DiMuonJpsiMassAlignment"),
            make_displaced_dimuon_mass_line(
                long_tracks, dileptons, name="Hlt1DisplacedDiMuonAlignment")
        ]

    with line_maker.bind(prefilter=prefilters_bx):
        lines = [line_maker(line) for line in lines]

    with line_maker.bind(prefilter=prefilters_no_bx):
        lines += [
            line_maker(
                make_beam_gas_line(
                    velo_tracks,
                    velo_states,
                    beam_crossing_type=1,
                    name="Hlt1BeamGas"))
        ]

    return lines


@configurable
def default_SMOG2_lines(velo_tracks,
                        long_tracks,
                        long_track_particles,
                        dihadrons,
                        v0s,
                        dileptons,
                        with_muon=True,
                        with_v0s=True,
                        min_z=-541.,
                        max_z=-341.):

    lines = [
        make_SMOG2_ditrack_line(
            dihadrons,
            m1=139.57,
            m2=493.68,
            mMother=1864.83,
            mWindow=150.,
            min_z=min_z,
            max_z=max_z,
            name="Hlt1_SMOG2_D2Kpi"),
        make_SMOG2_ditrack_line(
            dihadrons,
            m1=938.27,
            m2=938.27,
            mMother=2983.6,
            mWindow=150.,
            min_z=min_z,
            max_z=max_z,
            name="Hlt1_SMOG2_eta2pp"),
        make_SMOG2_kstopipi_line(
            dihadrons, min_z=min_z, max_z=max_z, name="Hlt1_SMOG2_KsToPiPi"),
        make_SMOG2_ditrack_line(
            dihadrons,
            minTrackPt=800.,
            min_z=min_z,
            max_z=max_z,
            name="Hlt1_SMOG2_2BodyGeneric",
            post_scaler=0.5),
        make_SMOG2_singletrack_line(
            long_tracks,
            long_track_particles,
            name="Hlt1_SMOG2_SingleTrack",
            post_scaler=0.5,
            min_z=min_z,
            max_z=max_z)
    ]

    if with_muon:
        lines += [
            make_SMOG2_dimuon_highmass_line(
                dileptons, name="Hlt1_SMOG2_DiMuonHighMass"),
            make_SMOG2_single_muon_line(
                long_tracks,
                long_track_particles,
                name="Hlt1_SMOG2_SingleMuon",
                post_scaler=0.5)
        ]

    if with_v0s:
        lines += [
            make_lambda2ppi_line(
                v0s, name="Hlt1_SMOG2_L02PPi", minPVZ=min_z, maxPVZ=max_z)
        ]

    return [line_maker(line) for line in lines]


def default_bgi_activity_lines(decoded_velo, decoded_calo, prefilter=[]):
    """
    Detector activity lines for BGI data collection.
    """
    # decoded_plume = decode_plume()
    bx_BB = make_bxtype(bx_type=3)
    bx_NoBB = make_invert_event_list(bx_BB, name="BX_NoBeamBeam")
    lines = [
        line_maker(
            make_velo_clusters_micro_bias_line(
                decoded_velo,
                name="Hlt1BGIVeloClustersMicroBias",
                min_velo_clusters=5,
            ),
            prefilter=prefilter + [bx_NoBB]),
        line_maker(
            make_calo_digits_minADC_line(
                decoded_calo,
                name="Hlt1BGICaloDigits",
                minADC=60,
            ),
            prefilter=prefilter + [bx_NoBB]),
        # line_maker(
        #     make_plume_activity_line(
        #         decoded_plume,
        #         name="Hlt1BGIPlumeActivity",
        #         min_number_plume_adcs_over_min=1,
        #         min_plume_adc=276,
        #     ),
        #     prefilter=prefilter + [bx_NoBB]),
        # FIXME Hlt1BGIPlumeActivity can be re-enabled when v2 support
        #       is implemented in the Plume decoding.
    ]
    return lines


def default_bgi_pvs_lines(pvs, velo_states, prefilter=[]):
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
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPVsCylIRBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [pvs_z_ir])
    ]

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
                pre_scaler=1.,
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
                pre_scaler=1.,
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
                pre_scaler=1.,
                post_scaler=1.),
            prefilter=prefilter + [velo_states_z_down])
    ]

    velo_states_z_ir = make_checkPseudoPV(
        velo_states,
        name="BGIPseudoPVsIR",
        min_state_z=-250.,
        max_state_z=250.,
        max_state_rho_sq=max_cyl_rad_sq,
        min_local_nTracks=28.)
    lines += [
        line_maker(
            make_beam_line(
                name="Hlt1BGIPseudoPVsIRBeamBeam",
                beam_crossing_type=3,
                pre_scaler=1.,
                post_scaler=0.1),
            prefilter=prefilter + [velo_states_z_ir])
    ]

    return lines


def setup_hlt1_node(enablePhysics=True,
                    withMCChecking=False,
                    EnableGEC=False,
                    withSMOG2=False,
                    enableRateValidator=True,
                    with_ut=True,
                    with_lumi=True,
                    with_odin_filter=True,
                    with_calo=True,
                    with_muon=True,
                    with_v0s=True,
                    with_rich=False,
                    with_AC_split=False,
                    enableBGI=False,
                    velo_open=False,
                    enableDownstream=False,
                    tracking_type=TrackingType.FORWARD,
                    threshold_settings=get_thresholds("default"),
                    tae_passthrough=True,
                    tae_activity=True,
                    enableTupling=False,
                    data_quality=False):

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
        with_rich=with_rich)

    hlt1_config['reconstruction'] = reconstructed_objects

    gec = [make_gec(count_ut=with_ut)] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []
    beam_beam_filter = [make_bxtype(bx_type=3)]
    prefilters = odin_err_filter + beam_beam_filter + gec

    physics_lines = []
    if enablePhysics:
        with line_maker.bind(prefilter=prefilters):
            physics_lines += default_physics_lines(
                reconstructed_objects, with_calo, with_muon, with_v0s,
                threshold_settings, enableTupling)

    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"
    with line_maker.bind(prefilter=odin_err_filter):
        monitoring_lines = odin_monitoring_lines(with_lumi, lumiline_name,
                                                 lumilinefull_name)
        monitoring_lines += [
            line_maker(make_odin_calib_line(name="Hlt1ODINCalib"))
        ]
        physics_lines += [line_maker(make_passthrough_line())]

    if tae_passthrough:
        if tae_activity:

            tae_activity_filter = make_tae_activity_filter(
                reconstructed_objects["long_tracks"],
                reconstructed_objects["velo_tracks"])

            tae_filters = CompositeNode(
                "taefilter_node",
                beam_beam_filter + [tae_activity_filter,
                                    tae_filter()],
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
                make_passthrough_line(name="Hlt1ErrorBank", pre_scaler=0.01))
        ]

    velo_open_event = make_event_type(event_type="VeloOpen")
    with line_maker.bind(prefilter=prefilters + [velo_open_event]):
        monitoring_lines += [
            line_maker(
                make_velo_micro_bias_line(
                    reconstructed_objects["velo_tracks"],
                    name="Hlt1VeloMicroBiasVeloClosing",
                    post_scaler=3.e-2))
        ]

    if EnableGEC:
        with line_maker.bind(prefilter=odin_err_filter + gec):
            physics_lines += [
                line_maker(make_passthrough_line(name="Hlt1GECPassthrough"))
            ]

    if enableBGI:
        bgi_prefilters = odin_err_filter + gec
        physics_lines += default_bgi_activity_lines(
            decode_velo(), decode_calo(), bgi_prefilters)
        physics_lines += default_bgi_pvs_lines(
            reconstructed_objects["pvs"], reconstructed_objects["velo_states"],
            bgi_prefilters)

    monitoring_lines += alignment_monitoring_lines(
        reconstructed_objects, prefilters, odin_err_filter + gec, with_muon)

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:
        SMOG2_prefilters, SMOG2_lines = [], []

        lowMult_5 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            reconstructed_objects["ecal_clusters"],
            name="LowMult_5",
            minTracks=1,
            maxTracks=5)
        with line_maker.bind(prefilter=odin_err_filter + gec + [lowMult_5]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1GECPassThrough_LowMult5", pre_scaler=0.01))
            ]

        bx_BE = make_bxtype(bx_type=1)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1_BESMOG2_NoBias", pre_scaler=1.e-6))
            ]

        lowMult_10 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            reconstructed_objects["ecal_clusters"],
            name="LowMult_10",
            minTracks=1,
            maxTracks=10)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE, lowMult_10]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1_BESMOG2_LowMult10", pre_scaler=1.e-4))
            ]

        if EnableGEC:
            SMOG2_prefilters += gec

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_SMOG2_minimum_bias_line(
                        reconstructed_objects["velo_tracks"],
                        reconstructed_objects["velo_states"],
                        name="Hlt1_SMOG2_MinimumBias",
                        pre_scaler=0.05))
            ]

        SMOG2_prefilters += [
            make_checkPV(reconstructed_objects['pvs'], name='check_SMOG2_PV')
        ]

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1Passthrough_PV_in_SMOG2", pre_scaler=0.02))
            ]

            SMOG2_lines += default_SMOG2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["long_tracks"],
                reconstructed_objects["long_track_particles"],
                reconstructed_objects["dihadron_secondary_vertices"],
                reconstructed_objects["v0_secondary_vertices"],
                reconstructed_objects["dilepton_secondary_vertices"],
                with_muon, with_v0s)

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    persistency_node, persistency_algorithms = make_persistency(
        line_algorithms)

    hlt1_node = CompositeNode(
        "Allen", [lines, persistency_node],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config.update(persistency_algorithms)

    # This is used to measure the effect of downstream reconstruction on the final throughput. It should be removed once the real downstream line is implemented.
    if enableDownstream:
        hlt1_node = CompositeNode(
            "AllenWithDownstream", [
                hlt1_node,
                CompositeNode(
                    "DownstreamReconstruction",
                    prefilters + [
                        reconstructed_objects["downstream_tracks"]
                        ["dev_downstream_track_particles_view"]
                    ],
                    NodeLogic.LAZY_AND,
                    force_order=True)
            ],
            NodeLogic.NONLAZY_AND,
            force_order=False)

    if with_lumi:
        lumi_reco = lumi_reconstruction(
            gather_selections=hlt1_config['gather_selections'],
            lines=line_algorithms,
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
            odin_err_filter + [lumi_node],
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

    if data_quality:
        # Forward reconstructed long tracks are needed for that module
        # Matching method is already used in reconstructed_objects
        reconstructed_objects_forward = hlt1_reconstruction(
            "ODQV_forward",
            with_calo=with_calo,
            with_ut=with_ut,
            with_muon=with_muon,
            tracking_type=TrackingType.FORWARD)
        node = make_dq_node(reconstructed_objects,
                            reconstructed_objects_forward, line_algorithms)
        return node

    if not withMCChecking:
        hlt1_config['control_flow_node'] = hlt1_node
    else:
        validation_node = validator_node(
            reconstructed_objects, line_algorithms,
            includes_matching(tracking_type), with_ut, with_muon,
            with_AC_split, prefilters)
        hlt1_config['validator_node'] = validation_node

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)
        hlt1_config['control_flow_node'] = node

    return hlt1_config
