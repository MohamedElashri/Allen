###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import (line_maker, make_gec, make_checkPV, make_lowmult,
                             make_checkCylPV, make_checkPseudoPV,
                             make_invert_event_list)
from AllenConf.odin import make_bxtype, odin_error_filter, tae_filter
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line, make_kstopipi_line, make_two_track_line_ks, make_lambda2ppi_line
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line, make_two_track_mva_charm_xsec_line, make_two_ks_line
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line, make_displaced_dimuon_mass_line, make_di_muon_mass_align_line, make_pi02gammagamma_line
from AllenConf.hlt1_muon_lines import make_one_muon_track_line, make_single_high_pt_muon_line, make_single_high_pt_muon_no_muid_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line, make_di_muon_no_ip_line, make_di_muon_drell_yan_line
from AllenConf.hlt1_electron_lines import make_track_electron_mva_line, make_single_high_pt_electron_line, make_lowmass_noip_dielectron_line, make_displaced_dielectron_line, make_displaced_leptons_line, make_single_high_et_line
from AllenConf.hlt1_monitoring_lines import (
    make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line,
    make_odin_event_and_orbit_line, make_beam_gas_line,
    make_velo_clusters_micro_bias_line, make_calo_digits_minADC_line,
    make_plume_activity_line, make_n_displaced_velo_line,
    make_n_materialvertex_seed_line)
from AllenConf.hlt1_smog2_lines import (
    make_SMOG2_minimum_bias_line, make_SMOG2_dimuon_highmass_line,
    make_SMOG2_ditrack_line, make_SMOG2_singletrack_line)
from AllenConf.hlt1_photon_lines import make_bs2gammagamma_line
from AllenConf.persistency import make_gather_selections, make_sel_report_writer, make_global_decision, make_routingbits_writer, make_dec_reporter
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.plume_reconstruction import decode_plume
from AllenConf.enum_types import TrackingType, includes_matching


def default_physics_lines(reconstructed_objects, with_calo, with_muon):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    pvs = reconstructed_objects["pvs"]
    secondary_vertices = reconstructed_objects["secondary_vertices"]
    muon_stubs = reconstructed_objects["muon_stubs"]

    lines = [
        make_two_track_mva_charm_xsec_line(
            long_tracks, secondary_vertices, name="Hlt1TwoTrackMVACharmXSec"),
        make_kstopipi_line(
            long_tracks, secondary_vertices, name="Hlt1KsToPiPi"),
        make_track_mva_line(
            long_tracks, long_track_particles, name="Hlt1TrackMVA"),
        make_two_track_mva_line(
            long_tracks, secondary_vertices, name="Hlt1TwoTrackMVA"),
        make_two_track_line_ks(
            long_tracks, secondary_vertices, name="Hlt1TwoTrackKs"),
        make_d2kk_line(long_tracks, secondary_vertices, name="Hlt1D2KK"),
        make_d2kpi_line(long_tracks, secondary_vertices, name="Hlt1D2KPi"),
        make_d2pipi_line(long_tracks, secondary_vertices, name="Hlt1D2PiPi"),
        make_two_ks_line(long_tracks, secondary_vertices, name="Hlt1TwoKs"),
        make_lambda2ppi_line(secondary_vertices, name="Hlt1L02PPi")
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
                long_tracks, long_track_particles,
                name="Hlt1SingleHighPtMuon"),
            make_single_high_pt_muon_no_muid_line(
                long_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuonNoMuID"),
            make_low_pt_muon_line(
                long_tracks, long_track_particles, name="Hlt1LowPtMuon"),
            make_di_muon_mass_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonHighMass",
                enable_monitoring=True),
            make_di_muon_mass_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonLowMass",
                minHighMassTrackPt=500.,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=4.),
            make_di_muon_soft_line(
                long_tracks, secondary_vertices, name="Hlt1DiMuonSoft"),
            make_low_pt_di_muon_line(
                long_tracks, secondary_vertices, name="Hlt1LowPtDiMuon"),
            make_track_muon_mva_line(
                long_tracks, long_track_particles, name="Hlt1TrackMuonMVA"),
            make_di_muon_no_ip_line(long_tracks, secondary_vertices),
            make_di_muon_no_ip_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonNoIP_ss",
                pre_scaler_hash_string="di_muon_no_ip_ss_line_pre",
                post_scaler_hash_string="di_muon_no_ip_ss_line_post",
                ss_on=True,
                post_scaler=.1),
            make_di_muon_drell_yan_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonDrellYan_VLowMass",
                pre_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_vlow_mass_line_post",
                minMass=2900.,
                maxMass=5000.,
                pre_scaler=.2),
            make_di_muon_drell_yan_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonDrellYan_VLowMass_SS",
                pre_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_pre",
                post_scaler_hash_string=
                "di_muon_drell_yan_vlow_mass_SS_line_post",
                minMass=2900.,  # low enough to capture the J/psi
                maxMass=5000.,
                pre_scaler=.2,
                OppositeSign=False),
            make_di_muon_drell_yan_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonDrellYan",
                pre_scaler_hash_string="di_muon_drell_yan_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_line_post",
                minMass=5000.),
            make_di_muon_drell_yan_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonDrellYan_SS",
                pre_scaler_hash_string="di_muon_drell_yan_SS_line_pre",
                post_scaler_hash_string="di_muon_drell_yan_SS_line_post",
                minMass=5000.,
                OppositeSign=False,
            )
        ]

    if with_calo:
        ecal_clusters = reconstructed_objects["ecal_clusters"]
        calo_matching_objects = reconstructed_objects["calo_matching_objects"]

        lines += [
            make_track_electron_mva_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                name="Hlt1TrackElectronMVA"),
            make_single_high_pt_electron_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                name="Hlt1SingleHighPtElectron"),
            make_displaced_dielectron_line(
                long_tracks,
                secondary_vertices,
                calo_matching_objects,
                name="Hlt1DisplacedDielectron"),
            make_displaced_leptons_line(
                long_tracks,
                long_track_particles,
                calo_matching_objects,
                name="Hlt1DisplacedLeptons"),
            make_single_high_et_line(
                velo_tracks, calo_matching_objects, name="Hlt1SingleHighEt"),
            make_bs2gammagamma_line(
                ecal_clusters, velo_tracks, pvs, name="Hlt1Bs2GammaGamma"),
            make_pi02gammagamma_line(
                ecal_clusters,
                velo_tracks,
                pvs,
                name="Hlt1Pi02GammaGamma",
                pre_scaler_hash_string="p02gammagamma_line_pre",
                post_scaler_hash_string="p02gammagamma_line_post",
                pre_scaler=0.05),
        ]

        line_slices_mass = {
            "1": (5., 30.),
            "2": (30., 100.),
            "3": (100., 200.),
            "4": (200., 300.)
        }
        for subSample in ["prompt", "displaced"]:
            for label, limits in line_slices_mass.items():
                postscale_os = 0.3 if subSample == "prompt" else 1.0
                lines.append(
                    make_lowmass_noip_dielectron_line(
                        long_tracks,
                        secondary_vertices,
                        calo_matching_objects,
                        minMass=limits[0],
                        maxMass=limits[1],
                        minPTprompt=500.,
                        minPTdisplaced=0.,
                        minIPChi2Threshold=2,
                        selectPrompt=True if subSample == "prompt" else False,
                        name="Hlt1LowMassNoipDielectron_massSlice{}_{}".format(
                            label, subSample),
                        pre_scaler_hash_string=
                        "lowmass_noip_dielectron_massSlice{}_{}_pre".format(
                            label, subSample),
                        post_scaler=postscale_os))
                lines.append(
                    make_lowmass_noip_dielectron_line(
                        long_tracks,
                        secondary_vertices,
                        calo_matching_objects,
                        is_same_sign=True,
                        minMass=limits[0],
                        maxMass=limits[1],
                        minPTprompt=500.,
                        minPTdisplaced=0.,
                        minIPChi2Threshold=2,
                        selectPrompt=True if subSample == "prompt" else False,
                        name="Hlt1LowMassNoipDielectron_SS_massSlice{}_{}".
                        format(label, subSample),
                        pre_scaler_hash_string=
                        "lowmass_noip_dielectron_SS_massSlice{}_{}_pre".format(
                            label, subSample),
                        post_scaler=0.02,
                        post_scaler_hash_string=
                        "lowmass_noip_dielectron_SS_massSlice{}_{}_post".
                        format(label, subSample)))

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


def event_monitoring_lines(lumiline_name):
    lines = []
    lines.append(
        line_maker(make_beam_line(name="Hlt1NoBeam", beam_crossing_type=0)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BeamOne", beam_crossing_type=1)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BeamTwo", beam_crossing_type=2)))
    lines.append(
        line_maker(make_beam_line(name="Hlt1BothBeams", beam_crossing_type=3)))
    lines.append(
        line_maker(make_odin_event_type_line(odin_event_type="VeloOpen")))
    return lines


def alignment_monitoring_lines(reconstructed_objects, with_muon=True):

    velo_tracks = reconstructed_objects["velo_tracks"]
    material_interaction_tracks = reconstructed_objects[
        "material_interaction_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    velo_states = reconstructed_objects["velo_states"]
    secondary_vertices = reconstructed_objects["secondary_vertices"]

    lines = [
        make_velo_micro_bias_line(velo_tracks, name="Hlt1VeloMicroBias"),
        make_rich_1_line(
            long_tracks, long_track_particles, name="Hlt1RICH1Alignment"),
        make_rich_2_line(
            long_tracks, long_track_particles, name="Hlt1RICH2Alignment"),
        make_beam_gas_line(
            velo_tracks, velo_states, beam_crossing_type=1,
            name="Hlt1BeamGas"),
        make_d2kpi_line(
            long_tracks, secondary_vertices, name="Hlt1D2KPiAlignment"),
        make_n_displaced_velo_line(material_interaction_tracks, n_tracks=3),
        make_n_materialvertex_seed_line(material_interaction_tracks)
    ]

    if with_muon:
        lines += [
            make_di_muon_mass_align_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DiMuonHighMassAlignment"),
            make_di_muon_mass_align_line(
                long_tracks,
                secondary_vertices,
                minMass=2500.,
                name="Hlt1DiMuonJpsiMassAlignment"),
            make_displaced_dimuon_mass_line(
                long_tracks,
                secondary_vertices,
                name="Hlt1DisplacedDiMuonAlignment")
        ]

    return [line_maker(line) for line in lines]


def default_smog2_lines(velo_tracks,
                        long_tracks,
                        long_track_particles,
                        secondary_vertices,
                        with_muon=True):

    lines = [
        make_SMOG2_ditrack_line(
            secondary_vertices,
            m1=139.57,
            m2=493.68,
            mMother=1864.83,
            mWindow=150.,
            name="Hlt1_SMOG2_D2Kpi"),
        make_SMOG2_ditrack_line(
            secondary_vertices,
            m1=938.27,
            m2=938.27,
            mMother=2983.6,
            mWindow=150.,
            name="Hlt1_SMOG2_eta2pp"),
        make_SMOG2_ditrack_line(
            secondary_vertices,
            minTrackPt=800.,
            name="Hlt1_SMOG2_2BodyGeneric"),
        make_SMOG2_singletrack_line(
            long_tracks, long_track_particles, name="Hlt1_SMOG2_SingleTrack")
    ]

    if with_muon:
        lines.append(
            make_SMOG2_dimuon_highmass_line(
                secondary_vertices, name="Hlt1_SMOG2_DiMuonHighMass"))

    return [line_maker(line) for line in lines]


def default_bgi_activity_lines(decoded_velo, decoded_calo, prefilter=[]):
    """
    Detector activity lines for BGI data collection.
    """
    decoded_plume = decode_plume()
    bx_BB = make_bxtype("BX_BeamBeam", bx_type=3)
    bx_NoBB = make_invert_event_list(bx_BB, name="BX_NoBeamBeam")
    lines = [
        line_maker(
            make_velo_clusters_micro_bias_line(
                decoded_velo,
                name="Hlt1BGIVeloClustersMicroBias",
                min_velo_clusters=30,
            ),
            prefilter=prefilter + [bx_NoBB]),
        line_maker(
            make_calo_digits_minADC_line(
                decoded_calo,
                name="Hlt1BGICaloDigits",
                minADC=100,
            ),
            prefilter=prefilter + [bx_NoBB]),
        line_maker(
            make_plume_activity_line(
                decoded_plume,
                name="Hlt1BGIPlumeActivity",
                min_plume_adc=406,
            ),
            prefilter=prefilter + [bx_NoBB])
    ]
    return lines


def default_bgi_pvs_lines(pvs, velo_states, prefilter=[]):
    """
    Primary vertex lines for various bunch crossing types composed from
    new PV filters and beam crossing lines.
    """
    mm = 1.0  # from SystemOfUnits.h
    max_cyl_rad_sq = (3 * mm)**2
    bx_BB = make_bxtype("BX_BeamBeam", bx_type=3)
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


@configurable
def setup_hlt1_node(enablePhysics=True,
                    withMCChecking=False,
                    EnableGEC=True,
                    withSMOG2=False,
                    enableRateValidator=True,
                    with_ut=True,
                    with_lumi=True,
                    with_odin_filter=True,
                    with_calo=True,
                    with_muon=True,
                    enableBGI=False,
                    tracking_type=TrackingType.FORWARD,
                    tae_passthrough=True):

    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(
        with_calo=with_calo,
        with_ut=with_ut,
        with_muon=with_muon,
        tracking_type=tracking_type)

    hlt1_config['reconstruction'] = reconstructed_objects

    gec = [make_gec(count_ut=with_ut)] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []
    prefilters = odin_err_filter + gec

    physics_lines = []
    if enablePhysics:
        with line_maker.bind(prefilter=prefilters):
            physics_lines += default_physics_lines(reconstructed_objects,
                                                   with_calo, with_muon)

    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"
    with line_maker.bind(prefilter=odin_err_filter):
        monitoring_lines = odin_monitoring_lines(with_lumi, lumiline_name,
                                                 lumilinefull_name)
        physics_lines += [line_maker(make_passthrough_line())]

    if tae_passthrough:
        with line_maker.bind(prefilter=prefilters + [tae_filter()]):
            physics_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1TAEPassthrough", pre_scaler=1))
            ]

    if EnableGEC:
        with line_maker.bind(prefilter=prefilters):
            physics_lines += [
                line_maker(make_passthrough_line(name="Hlt1GECPassthrough"))
            ]

    if enableBGI:
        physics_lines += default_bgi_activity_lines(decode_velo(),
                                                    decode_calo(), prefilters)
        physics_lines += default_bgi_pvs_lines(
            reconstructed_objects["pvs"], reconstructed_objects["velo_states"],
            prefilters)

    with line_maker.bind(prefilter=prefilters):
        monitoring_lines += alignment_monitoring_lines(reconstructed_objects,
                                                       with_muon)

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
            name="LowMult_5",
            minTracks=1,
            maxTracks=5)
        with line_maker.bind(prefilter=prefilters + [lowMult_5]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1GECPassThrough_LowMult5"))
            ]

        bx_BE = make_bxtype("BX_BeamEmpty", bx_type=1)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE]):
            SMOG2_lines += [
                line_maker(make_passthrough_line(name="Hlt1_BESMOG2_NoBias"))
            ]

        lowMult_10 = make_lowmult(
            reconstructed_objects['velo_tracks'],
            name="LowMult_10",
            minTracks=1,
            maxTracks=10)
        with line_maker.bind(prefilter=odin_err_filter + [bx_BE, lowMult_10]):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1_BESMOG2_LowMult10"))
            ]

        if EnableGEC:
            SMOG2_prefilters += gec

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_SMOG2_minimum_bias_line(
                        reconstructed_objects["velo_tracks"],
                        reconstructed_objects["velo_states"],
                        name="Hlt1_SMOG2_MinimumBias"))
            ]

        SMOG2_prefilters += [
            make_checkPV(
                reconstructed_objects['pvs'],
                name='check_SMOG2_PV',
                minZ=-541,
                maxZ=-341)
        ]

        with line_maker.bind(prefilter=odin_err_filter + SMOG2_prefilters):
            SMOG2_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1Passthrough_PV_in_SMOG2"))
            ]

            SMOG2_lines += default_smog2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["long_tracks"],
                reconstructed_objects["long_track_particles"],
                reconstructed_objects["secondary_vertices"], with_muon)

        line_algorithms += [tup[0] for tup in SMOG2_lines]
        line_nodes += [tup[1] for tup in SMOG2_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections = make_gather_selections(lines=line_algorithms)
    global_decision = make_global_decision(lines=line_algorithms)
    dec_reporter = make_dec_reporter(lines=line_algorithms)
    sel_reports = make_sel_report_writer(lines=line_algorithms)

    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            dec_reporter,
            global_decision,
            make_routingbits_writer(lines=line_algorithms),
            *sel_reports["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config['gather_selections'] = gather_selections
    hlt1_config['dec_reporter'] = dec_reporter
    hlt1_config['sel_reports'] = sel_reports
    hlt1_config['global_decision'] = global_decision

    if with_lumi:
        lumi_node = CompositeNode(
            "AllenLumiNode",
            lumi_reconstruction(
                gather_selections=gather_selections,
                lines=line_algorithms,
                lumiline_name=lumiline_name,
                lumilinefull_name=lumilinefull_name,
                with_muon=with_muon)["algorithms"],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        lumi_with_prefilter = CompositeNode(
            "LumiWithPrefilter",
            odin_err_filter + [lumi_node],
            NodeLogic.LAZY_AND,
            force_order=True)

        hlt1_config['lumi_node'] = lumi_with_prefilter

        hlt1_node = CompositeNode(
            "AllenWithLumi", [hlt1_node, lumi_with_prefilter],
            NodeLogic.NONLAZY_AND,
            force_order=False)

    if enableRateValidator:
        hlt1_node = CompositeNode(
            "AllenRateValidation", [
                hlt1_node,
                rate_validation(lines=line_algorithms),
            ],
            NodeLogic.NONLAZY_AND,
            force_order=True)

    if not withMCChecking:
        hlt1_config['control_flow_node'] = hlt1_node
    else:
        validation_node = validator_node(
            reconstructed_objects, line_algorithms,
            includes_matching(tracking_type), with_ut, with_muon)
        hlt1_config['validator_node'] = validation_node

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)
        hlt1_config['control_flow_node'] = node

    return hlt1_config
