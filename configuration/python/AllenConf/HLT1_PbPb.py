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
from AllenConf.filters import *
from AllenConf.utils import line_maker
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_calibration_lines import *
from AllenConf.hlt1_monitoring_lines import *
from AllenConf.hlt1_heavy_ions_lines import *

from AllenConf.hlt1_inclusive_hadron_lines import *
from AllenConf.hlt1_charm_lines import *
from AllenConf.hlt1_muon_lines import *
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.odin import make_bxtype, odin_error_filter, tae_filter, make_event_type, make_odin_orbit
from AllenConf.persistency import make_persistency
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.enum_types import TrackingType, ActivityType, includes_matching
from .HLT1 import default_bgi_activity_lines


def default_physics_lines(reconstructed_objects, prescale, reco_particles,
                          with_muon):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_tracks = reconstructed_objects["long_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    decoded_calo = reconstructed_objects["decoded_calo"]
    pvs = reconstructed_objects["pvs"]
    dihadrons = reconstructed_objects["dihadron_secondary_vertices"]
    dileptons = reconstructed_objects["dilepton_secondary_vertices"]
    v0s = reconstructed_objects["v0_secondary_vertices"]
    muon_stubs = reconstructed_objects["muon_stubs"]

    lines = [
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbMicroBias",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            min_pvs_PbPb=1,
            decoded_calo=decoded_calo,
            pre_scaler=0.01 if prescale else 1),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbMBOneTrack",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_velo_tracks_PbPb=1,
            pre_scaler=0.01),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbSMOGMicroBias",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_SMOG=1,
            pre_scaler=0.01 if prescale else 1),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbSMOGMBOneTrack",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_velo_tracks_SMOG=1,
            pre_scaler=0.01 if prescale else 1),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbHadronic",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_PbPb=1,
            min_ecal_e=310000),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbSMOGHadronic",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_SMOG=1,
            min_ecal_e=94000),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbUPCMB",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            max_ecal_e=94000,
            max_velo_tracks_SMOG=0,
            min_long_tracks=1,
            min_velo_tracks_PbPb=2,
            pre_scaler=0.8 if prescale else 1)
    ]
    if reco_particles:
        lines += [
            make_kstopipi_line(
                long_tracks, v0s, name="Hlt1KsToPiPi", post_scaler=0.001),
            make_kstopipi_line(
                long_tracks,
                v0s,
                name="Hlt1KsToPiPiDoubleMuonMisID",
                double_muon_misid=True,
            ),
            make_d2kk_line(long_tracks, dihadrons, name="Hlt1D2KK"),
            make_d2kpi_line(long_tracks, dihadrons, name="Hlt1D2KPi"),
            make_d2pipi_line(long_tracks, dihadrons, name="Hlt1D2PiPi"),
            make_lambda2ppi_line(v0s, name="Hlt1L02PPi")
        ]
        if with_muon:
            muonid = reconstructed_objects["muonID"]
            lines += [
                make_di_muon_mass_line(
                    long_tracks, dileptons, muonid, name="Hlt1DiMuonHighMass"),
                make_di_muon_mass_line(
                    long_tracks,
                    dileptons,
                    muonid,
                    name="Hlt1DiMuonLowMass",
                    enable_monitoring=False,
                    minHighMassTrackPt=500.,
                    minHighMassTrackP=3000.,
                    minMass=0.,
                    maxDoca=0.2,
                    maxVertexChi2=25.,
                    minIPChi2=4.)
            ]

    return [line_maker(line) for line in lines]


def upc_physics_lines(reconstructed_objects):

    pvs = reconstructed_objects["pvs"]
    velo_tracks = reconstructed_objects["velo_tracks"]
    ecal_clusters = reconstructed_objects["ecal_clusters"]

    # upc photon lines
    lines = [
        make_diphoton_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCDiPhoton_LowPt_Ycut",
            calo=ecal_clusters,
            velo_tracks=velo_tracks,
            pvs=pvs,
            min_absY=100,
            max_velo_tracks=10,
            max_ecal_clusters=10,
            maxPt=1000),
        make_photon_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCPhoton_Ycut",
            calo=ecal_clusters,
            min_absY=100,
            max_ecal_clusters=10,
            pre_scaler=0.02),
        make_photon_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCPhoton",
            calo=ecal_clusters,
            max_ecal_clusters=10,
            pre_scaler=0.002),
        make_diphoton_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCDiPhoton_HighMass",
            calo=ecal_clusters,
            velo_tracks=velo_tracks,
            pvs=pvs,
            minMass=1300,
            minEt_clusters=500,
            maxPt=2000,
            max_velo_tracks=10,
            max_ecal_clusters=10,
            mass_histogram_range=[1300, 40000],
            pre_scaler=0.1),
        make_photon_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCPhoton_HighEt",
            calo=ecal_clusters,
            minEt=800,
            max_ecal_clusters=10,
            pre_scaler=0.1)
    ]
    return [line_maker(line) for line in lines]


def mini_physics_lines(reconstructed_objects):

    velo_tracks = reconstructed_objects["velo_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]
    decoded_calo = reconstructed_objects["decoded_calo"]
    pvs = reconstructed_objects["pvs"]
    ecal_clusters = reconstructed_objects["ecal_clusters"]

    # default ion lines
    lines = [
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbUPCMB",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            max_ecal_e=94000,
            min_long_tracks=1,
            min_velo_tracks_PbPb=2,
            pre_scaler=1),
        make_photon_lowmult_line(
            name="Hlt1HeavyIonPbPbUPCPhoton",
            pre_scaler_hash_string="PbPbUPCPhoton_line_pre",
            post_scaler_hash_string="PbPbUPCPhoton_line_post",
            calo=ecal_clusters,
            max_ecal_clusters=10)
    ]

    return [line_maker(line) for line in lines]


def odin_monitoring_lines(lumiline_name, lumilinefull_name, with_gec,
                          odin_err_filter, odin_lumi):
    lines = []

    if with_gec:
        with line_maker.bind(prefilter=odin_err_filter):
            lines.append(
                line_maker(
                    make_odin_event_type_with_decoding_line(
                        name=lumiline_name, odin_event_type='Lumi')))
    else:
        with line_maker.bind(prefilter=odin_err_filter + [odin_lumi]):
            lines += [
                line_maker(
                    make_passthrough_line(name=lumiline_name, pre_scaler=1.))
            ]

    odin_orbit = make_odin_orbit(odin_orbit_modulo=30, odin_orbit_remainder=1)
    with line_maker.bind(prefilter=odin_err_filter + [odin_lumi, odin_orbit]):
        lines += [
            line_maker(
                make_passthrough_line(name=lumilinefull_name, pre_scaler=1.))
        ]

    return lines


def alignment_monitoring_lines(reconstructed_objects,
                               reco_particles,
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
            long_tracks, long_track_particles, name="Hlt1RICH1Alignment"),
        make_rich_2_line(
            long_tracks, long_track_particles, name="Hlt1RICH2Alignment"),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=300,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeedsDownstreamz",
            pre_scaler=0.005),
        make_z_range_materialvertex_seed_line(
            material_interaction_tracks,
            min_z_materialvertex_seed=700,
            max_z_materialvertex_seed=1000,
            name="Hlt1MaterialVertexSeeds_DWFS",
            pre_scaler=0.1)
    ]

    if reco_particles:
        lines += [
            make_d2kpi_align_line(
                long_tracks, dihadrons, name="Hlt1D2KPiAlignment"),
            make_dst_line(dstars, name="Hlt1Dst2D0PiAlignment")
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
                    post_scaler=0.001),
                make_di_muon_mass_line(
                    long_tracks,
                    dileptons,
                    muonid,
                    maxChi2Corr=1.8,
                    name="Hlt1UpsilonAlignment",
                    minMass=8000.,
                    minHighMassTrackPt=550),
                make_det_jpsitomumu_tap_line(
                    long_tracks,
                    dihadrons,
                    name="Hlt1DetJpsiToMuMuPosTagLine",
                    posTag=True,
                    enable_monitoring=True,
                    enable_tupling=False),
                make_det_jpsitomumu_tap_line(
                    long_tracks,
                    dihadrons,
                    name="Hlt1DetJpsiToMuMuNegTagLine",
                    posTag=False,
                    enable_monitoring=True,
                    enable_tupling=False)
            ]

    return [line_maker(line) for line in lines]


def setup_hlt1_node(withMCChecking=False,
                    max_ecal_upc=94000,
                    min_ecal_hadro=94000,
                    EnableGEC=False,
                    enableBGI=True,
                    enableRateValidator=True,
                    with_lumi=True,
                    with_odin_filter=True,
                    tracking_type=TrackingType.FORWARD,
                    with_ut=True,
                    with_AC_split=False,
                    prescale=False,
                    with_calo=True,
                    with_muon=True,
                    with_rich=True,
                    velo_open=False,
                    enableDownstream=True,
                    reco_particles=True,
                    bx_type=None,
                    tae_passthrough=True,
                    tae_activity=True,
                    minimal_activity_type=ActivityType.VELO_CLUSTERS,
                    ActivityForClosing=ActivityType.VELO_CLUSTERS,
                    DisableLinesDuringVPClosing=False,
                    mini=False):

    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(
        with_ut=with_ut,
        tracking_type=tracking_type,
        with_AC_split=with_AC_split)

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

    # GEC for UPC events
    decoded_calo = decode_calo()
    gec_ecal_upc = [
        make_checkEcalEnergy(
            decoded_calo['dev_total_ecal_e'],
            name='CheckEcalEnergyUPC',
            ecalCut=max_ecal_upc,
            cutHigh=True)
    ]

    gec_photon_nvelo_upc = [
        make_lowmult(
            reconstructed_objects["velo_tracks"],
            reconstructed_objects["ecal_clusters"],
            name="CheckPhotonUPC",
            maxTracks=10,
            max_ecal_clusters=10)
    ]

    gec_ecal_periph = [
        make_checkEcalEnergy(
            decoded_calo['dev_total_ecal_e'],
            name='CheckEcalEnergyHadronic',
            ecalCut=min_ecal_hadro,
            cutHigh=False)
    ]

    gec = [
        make_gec(
            count_ut=False,
            count_velo=True,
            max_scifi_clusters=30000,
            max_velo_clusters=60000)
    ] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []

    velo_open_event = make_event_type(event_type="VeloOpen")
    velo_closed = [
        make_event_type(
            name="ODIN_EvenType_VeloClosed",
            event_type="VeloOpen",
            invert=True)
    ] if DisableLinesDuringVPClosing else []

    #activity filter needed for SD monitoring
    activity_filter = make_minimal_activity_filter(
        reconstructed_objects,
        minimal_activity_type,
        min_activity=200,
        max_activity=999999999)
    #activity filter needed for SD monitoring

    velo_closing_gec = []

    #reject extremely busy events that give rise to fake PVs for VeloClosingMon and VeloMon
    pv_activity_filter = make_minimal_activity_filter(
        reconstructed_objects,
        minimal_activity_type=ActivityType.PRIMARY_VERTICES,
        min_activity=1.,
        max_activity=100.)
    velo_clusters_filter = [
        make_gec(
            gec_name="closing_filter",
            count_velo=True,
            count_scifi=False,
            count_ut=False,
            min_velo_clusters=200,
            max_velo_clusters=30000)
    ]

    if ActivityForClosing == ActivityType.VELO_CLUSTERS:
        velo_closing_gec = velo_clusters_filter
    elif ActivityForClosing == ActivityType.PRIMARY_VERTICES:
        velo_closing_gec = pv_activity_filter
    else:
        raise Exception("VeloClosing activity not supported")

    veloMicroBias_scifi_clusters_filter = [
        scifi_gec(
            'veloMicroBias_scifi_clusters_filter',
            min_clusters=0,
            max_clusters=7000)
    ]
    veloMicroBias_velo_clusters_filter = [
        velo_gec(
            'veloMicroBias_velo_clusters_filter',
            min_clusters=200,
            max_clusters=7000)
    ]
    veloMicroBias_clusters_filter = [
        CompositeNode(
            "veloMicroBias_clusters_filter_node",
            veloMicroBias_scifi_clusters_filter +
            veloMicroBias_velo_clusters_filter,
            NodeLogic.LAZY_AND,
            force_order=False)
    ]

    if ActivityForClosing == ActivityType.VELO_CLUSTERS:
        veloMicroBias_gec = veloMicroBias_clusters_filter
    elif ActivityForClosing == ActivityType.PRIMARY_VERTICES:
        veloMicroBias_gec = pv_activity_filter
    else:
        raise Exception("VeloClosing activity not supported")
    bx_BB = [make_bxtype(bx_type=3)]

    prefilters = odin_err_filter + gec + velo_closed
    prefilter_upc = prefilters + gec_ecal_upc + velo_closed
    prefilter_photon_velo_upc = prefilters + gec_photon_nvelo_upc + velo_closed
    prefilter_hadronic = prefilters + gec_ecal_periph + velo_closed
    prefilter_veloMicroBias = odin_err_filter + bx_BB + velo_closed + veloMicroBias_gec
    # The lumi filter should be the same as for the physics lines but without the bx_type filter
    prefilters_lumi = odin_err_filter
    if mini:
        prefilters_lumi = prefilters_lumi + gec_ecal_upc
    else:
        prefilters_lumi = prefilters_lumi + gec
    # the filters for the BGI lines must exclude the BX filters
    prefilters_bgi = odin_err_filter + gec
    prefilter_upc_bgi = prefilters_bgi + gec_ecal_upc

    if bx_type is not None:
        if not isinstance(bx_type, list):
            bx_type = [bx_type]
        prefilters = prefilters + [
            CompositeNode(
                "bx_selection",
                [make_bxtype(bx_type=ibx_type)
                 for ibx_type in bx_type], NodeLogic.NONLAZY_OR)
        ]

    # Setup physics lines.
    physics_lines = []
    if mini:
        with line_maker.bind(prefilter=prefilter_upc):
            physics_lines = mini_physics_lines(reconstructed_objects)
        with line_maker.bind(prefilter=prefilter_hadronic):
            physics_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1GECCentPassthrough", pre_scaler=1))
            ]
        with line_maker.bind(prefilter=prefilter_upc):
            physics_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1GECUPCPassthrough"))
            ]
        with line_maker.bind(prefilter=prefilters):
            physics_lines += [
                line_maker(
                    make_passthrough_line(name="Hlt1GECSciFiPassthrough"))
            ]
    else:
        with line_maker.bind(prefilter=prefilters):
            physics_lines = default_physics_lines(
                reconstructed_objects, prescale, reco_particles, with_muon)
        with line_maker.bind(prefilter=prefilter_photon_velo_upc):
            physics_lines += upc_physics_lines(reconstructed_objects)

            if EnableGEC:
                physics_lines += [
                    line_maker(
                        make_passthrough_line(name="Hlt1GECPassthrough"))
                ]

    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"
    # decoding based lumi line
    with line_maker.bind(prefilter=odin_err_filter):
        physics_lines += [line_maker(make_passthrough_line())]

    monitoring_lines = []
    if with_lumi:
        odin_lumi_event = make_event_type(event_type='Lumi')
        monitoring_lines += odin_monitoring_lines(
            lumiline_name, lumilinefull_name, EnableGEC, odin_err_filter,
            odin_lumi_event)

    with line_maker.bind(prefilter=odin_err_filter):
        monitoring_lines += [
            line_maker(make_odin_calib_line(name="Hlt1ODINCalib"))
        ]
    #Minimal activity line, for SD monitoring
    with line_maker.bind(prefilter=odin_err_filter + activity_filter):
        monitoring_lines += [
            line_maker(
                make_passthrough_line(
                    name="Hlt1MinimalActivity", pre_scaler=0.01))
        ]

    # alignment lines within the GEC
    with line_maker.bind(prefilter=(prefilter_upc if mini else prefilters)):
        monitoring_lines += alignment_monitoring_lines(
            reconstructed_objects, reco_particles, with_muon)

    # velo microbias lines for Velo closing & alignment inside minimal activity filter
    with line_maker.bind(prefilter=odin_err_filter + [velo_open_event] + gec +
                         velo_closing_gec):
        monitoring_lines += [
            line_maker(
                make_velo_micro_bias_line(
                    reconstructed_objects["velo_tracks"],
                    name="Hlt1VeloMicroBiasVeloClosing",
                    pre_scaler=1.,
                    post_scaler=1.))
        ]
    with line_maker.bind(prefilter=prefilter_veloMicroBias):
        monitoring_lines += [
            line_maker(
                make_velo_micro_bias_line(
                    reconstructed_objects["velo_tracks"],
                    name="Hlt1VeloMicroBias",
                    pre_scaler=0.15,
                    post_scaler=1.,
                    min_velo_tracks=3))
        ]

    bx_BE = make_bxtype(bx_type=1)
    with line_maker.bind(
            prefilter=(prefilter_upc if mini else prefilters) + [bx_BE]):
        monitoring_lines += [
            line_maker(
                make_beam_gas_line(
                    reconstructed_objects["velo_tracks"],
                    reconstructed_objects["velo_states"],
                    beam_crossing_type=1,
                    name="Hlt1BeamGas"))
        ]

    if tae_passthrough:
        if tae_activity:

            #tae_activity_filter = make_tae_activity_filter(
            #    reconstructed_objects["long_tracks"],
            #    reconstructed_objects["velo_tracks"],
            #    use_long_tracks=True)

            tae_filters = CompositeNode(
                "taefilter_node",
                gec + pv_activity_filter + [tae_filter()],
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

    if enableBGI:
        monitoring_lines += default_bgi_activity_lines(
            reconstructed_objects["pvs"],
            reconstructed_objects["velo_states"],
            decoded_velo=decode_velo(),
            decoded_calo=decoded_calo,
            prefilter=(prefilter_upc_bgi if mini else prefilters_bgi),
            enableBGI_full=False,
            PbPb_collision=True)

    with line_maker.bind(prefilter=[sd_error_filter()]):
        physics_lines += [
            line_maker(
                make_passthrough_line(name="Hlt1ErrorBank", pre_scaler=0.01))
        ]

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # list of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    persistency_node, persistency_algorithms = make_persistency(
        line_algorithms)

    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            persistency_node,
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    hlt1_config['line_nodes'] = line_nodes
    hlt1_config['line_algorithms'] = line_algorithms
    hlt1_config.update(persistency_algorithms)

    if with_lumi:
        lumi_node = CompositeNode(
            "AllenLumiNode",
            lumi_reconstruction(
                gather_selections=hlt1_config['gather_selections'],
                lumiline_name=lumiline_name,
                lumilinefull_name=lumilinefull_name)["algorithms"],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        lumi_with_prefilter = CompositeNode(
            "LumiWithPrefilter",
            prefilters_lumi + [lumi_node],
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
            includes_matching(tracking_type), with_ut, with_muon,
            with_AC_split, prefilters)
        hlt1_config['validator_node'] = validation_node

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)
        hlt1_config['control_flow_node'] = node

    return hlt1_config
