###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import make_gec, line_maker, make_checkEcalEnergy
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line, make_displaced_dimuon_mass_line, make_di_muon_mass_align_line, make_pi02gammagamma_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line, make_odin_event_type_with_decoding_line, make_odin_event_and_orbit_line, make_beam_gas_line
from AllenConf.hlt1_heavy_ions_lines import make_heavy_ion_event_line
from AllenConf.hlt1_inclusive_hadron_lines import make_kstopipi_line, make_lambda2ppi_line
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line
from AllenConf.hlt1_muon_lines import make_one_muon_track_line, make_di_muon_mass_line, make_displaced_dimuon_line
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.validators import rate_validation
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenConf.odin import odin_error_filter, make_bxtype, tae_filter
from AllenConf.persistency import make_gather_selections, make_global_decision, make_sel_report_writer, make_routingbits_writer, make_dec_reporter
from AllenConf.lumi_reconstruction import lumi_reconstruction
from AllenConf.enum_types import TrackingType, includes_matching
from .HLT1 import default_bgi_activity_lines, default_bgi_pvs_lines


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
    v0_pairs = reconstructed_objects["v0_pairs"]
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
            pre_scaler=0.01 if prescale else 1),
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
            name="Hlt1HeavyIonPbPbPeripheral",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_PbPb=1,
            min_ecal_e=310000,
            max_ecal_e=14860000),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbSMOGHadronic",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_SMOG=1,
            min_ecal_e=94000),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbCentral",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            min_pvs_PbPb=1,
            min_ecal_e=14860000,
            pre_scaler=0.01 if prescale else 1),
        make_heavy_ion_event_line(
            name="Hlt1HeavyIonPbPbUPCMB",
            velo_tracks=velo_tracks,
            long_track_particles=long_track_particles,
            pvs=pvs,
            decoded_calo=decoded_calo,
            max_ecal_e=94000,
            min_long_tracks=1,
            min_velo_tracks_PbPb=2,
            pre_scaler=0.8 if prescale else 1)
    ]
    if reco_particles:
        lines += [
            make_kstopipi_line(
                long_tracks, v0s, name="Hlt1KsToPiPi", post_scaler=0.001),
            make_d2kk_line(long_tracks, dihadrons, name="Hlt1D2KK"),
            make_d2kpi_line(long_tracks, dihadrons, name="Hlt1D2KPi"),
            make_d2pipi_line(long_tracks, dihadrons, name="Hlt1D2PiPi"),
            make_lambda2ppi_line(v0s, name="Hlt1L02PPi")
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
                make_di_muon_mass_line(
                    long_tracks, dileptons, name="Hlt1DiMuonHighMass"),
                make_di_muon_mass_line(
                    long_tracks,
                    dileptons,
                    name="Hlt1DiMuonLowMass",
                    minHighMassTrackPt=500.,
                    minHighMassTrackP=3000.,
                    minMass=0.,
                    maxDoca=0.2,
                    maxVertexChi2=25.,
                    minIPChi2=4.)
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
    ]

    return [line_maker(line) for line in lines]


def odin_monitoring_lines(with_lumi,
                          lumiline_name,
                          lumilinefull_name,
                          with_gec=False):
    lines = []
    if with_lumi:
        if with_gec:
            #explicitly require decoding of subdetectors outside of the GEC
            lines.append(
                make_odin_event_type_with_decoding_line(
                    name=lumiline_name, odin_event_type='Lumi'))
        else:
            lines.append(
                make_odin_event_type_line(
                    name=lumiline_name, odin_event_type='Lumi'))
        lines.append(
            make_odin_event_and_orbit_line(
                name=lumilinefull_name,
                odin_event_type='Lumi',
                odin_orbit_modulo=30,
                odin_orbit_remainder=1))

    return [line_maker(line) for line in lines]


def alignment_monitoring_lines(reconstructed_objects,
                               reco_particles,
                               with_muon=True):

    velo_tracks = reconstructed_objects["velo_tracks"]
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
        make_beam_gas_line(
            velo_tracks, velo_states, beam_crossing_type=1, name="Hlt1BeamGas")
    ]

    if reco_particles:
        lines += [
            make_d2kpi_line(long_tracks, dihadrons, name="Hlt1D2KPiAlignment")
        ]
        if with_muon:
            lines += [
                make_di_muon_mass_align_line(
                    long_tracks, dileptons,
                    name="Hlt1DiMuonHighMassAlignment"),
                make_di_muon_mass_align_line(
                    long_tracks,
                    dileptons,
                    minMass=2500.,
                    name="Hlt1DiMuonJpsiMassAlignment"),
                make_displaced_dimuon_mass_line(
                    long_tracks,
                    dileptons,
                    name="Hlt1DisplacedDiMuonAlignment")
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
                    prescale=False,
                    with_muon=True,
                    reco_particles=False,
                    bx_type=None,
                    tae_passthrough=True,
                    mini=False):

    hlt1_config = {}

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(
        algorithm_name='PbPb_hlt1_reconstruction',
        with_ut=with_ut,
        tracking_type=tracking_type)
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

    gec_ecal_periph = [
        make_checkEcalEnergy(
            decoded_calo['dev_total_ecal_e'],
            name='CheckEcalEnergyHadronic',
            ecalCut=min_ecal_hadro,
            cutHigh=False)
    ]

    gec = [make_gec()] if EnableGEC else []
    odin_err_filter = [odin_error_filter("odin_error_filter")
                       ] if with_odin_filter else []

    # the filters for the BGI lines must exclude the BX filters
    prefilters_bgi = odin_err_filter + gec
    prefilter_upc_bgi = prefilters_bgi + gec_ecal_upc

    # all PbPb and PbSMOG lines will filter on bx types
    prefilters = odin_err_filter + gec
    if bx_type is not None:
        if not isinstance(bx_type, list): bx_type = [bx_type]
        prefilters = prefilters + [
            CompositeNode(
                "bx_selection",
                [make_bxtype(bx_type=ibx_type)
                 for ibx_type in bx_type], NodeLogic.NONLAZY_OR)
        ]
    prefilter_upc = prefilters + gec_ecal_upc
    prefilter_hadronic = prefilters + gec_ecal_periph

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

            if EnableGEC:
                physics_lines += [
                    line_maker(
                        make_passthrough_line(name="Hlt1GECPassthrough"))
                ]

    lumiline_name = "Hlt1ODINLumi"
    lumilinefull_name = "Hlt1ODIN1kHzLumi"
    # decoding based lumi line
    with line_maker.bind(prefilter=odin_err_filter):
        monitoring_lines = odin_monitoring_lines(with_lumi, lumiline_name,
                                                 lumilinefull_name, EnableGEC)

        physics_lines += [line_maker(make_passthrough_line())]

    # alignment lines within the GEC
    with line_maker.bind(prefilter=(prefilter_upc if mini else prefilters)):
        monitoring_lines += alignment_monitoring_lines(
            reconstructed_objects, reco_particles, with_muon)

    if tae_passthrough:
        with line_maker.bind(prefilter=odin_err_filter + [tae_filter()]):
            physics_lines += [
                line_maker(
                    make_passthrough_line(
                        name="Hlt1TAEPassthrough", pre_scaler=1))
            ]

    if enableBGI:
        monitoring_lines += default_bgi_activity_lines(
            decoded_velo=decode_velo(),
            decoded_calo=decoded_calo,
            prefilter=(prefilter_upc_bgi if mini else prefilters_bgi))
        monitoring_lines += default_bgi_pvs_lines(
            reconstructed_objects["pvs"],
            reconstructed_objects["velo_states"],
            prefilter=(prefilter_upc_bgi if mini else prefilters_bgi))

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # list of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    lines = CompositeNode(
        "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    global_decision = make_global_decision(lines=line_algorithms)
    gather_selections = make_gather_selections(lines=line_algorithms)
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
    hlt1_config['global_decision'] = global_decision
    hlt1_config['gather_selections'] = gather_selections
    hlt1_config['dec_reporter'] = dec_reporter
    hlt1_config['sel_reports'] = sel_reports

    if with_lumi:
        lumi_node = CompositeNode(
            "AllenLumiNode",
            lumi_reconstruction(
                gather_selections=gather_selections,
                lines=line_algorithms,
                lumiline_name=lumiline_name,
                lumilinefull_name=lumilinefull_name)["algorithms"],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        lumi_with_prefilter = CompositeNode(
            "LumiWithPrefilter",
            prefilters + [lumi_node],
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
