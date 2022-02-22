###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import initialize_number_of_events, mep_layout, gec, checkPV, lowMult
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line, make_kstopipi_line, make_two_track_line_ks
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line
from AllenConf.hlt1_muon_lines import make_single_high_pt_muon_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line
from AllenConf.hlt1_smog2_lines import make_SMOG2_minimum_bias_line, make_SMOG2_dimon_highmass_line, make_SMOG2_ditrack_line, make_SMOG2_singletrack_line

from AllenConf.validators import rate_validation
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin
from AllenConf.persistency import make_gather_selections, make_global_decision, make_sel_report_writer


# Helper function to make composite nodes with the gec
def make_line_composite_node(name, algos):
    return CompositeNode(
        name + "_node", algos, NodeLogic.LAZY_AND, force_order=True)


@configurable
def line_maker(line_algorithm, prefilter=None):

    if prefilter is None: node = line_algorithm
    else:
        if isinstance(prefilter, list):
            node = make_line_composite_node(
                line_algorithm.name, algos=prefilter + [line_algorithm])
        else:
            node = make_line_composite_node(
                line_algorithm.name, algos=[prefilter, line_algorithm])
    return line_algorithm, node

def passthrough_line(name='Hlt1Passthrough'):
    return line_maker(
        make_passthrough_line(
            name=name,
            pre_scaler_hash_string=name + "_line_pre",
            post_scaler_hash_string=name + "_line_post"))

def default_physics_lines(forward_tracks, long_track_particles,
                          secondary_vertices, name_suffix = ''):
    lines = []
    lines.append(
        line_maker(
            make_kstopipi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1KsToPiPi" + name_suffix)))
    lines.append(
        line_maker(
            make_track_mva_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1TrackMVA" + name_suffix)))
    lines.append(
        line_maker(
            make_two_track_mva_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1TwoTrackMVA" + name_suffix)))
    lines.append(
        line_maker(
            "Hlt1TwoTrackKs",
            make_two_track_line_ks(forward_tracks, secondary_vertices),
            enableGEC=True))
    lines.append(
        line_maker(
            make_two_track_line_ks(
                forward_tracks,
                secondary_vertices,
                name="Hlt1TwoTrackKs" + name_suffix)))
    lines.append(
        line_maker(
            make_single_high_pt_muon_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1SingleHighPtMuon" + name_suffix)))
    lines.append(
        line_maker(
            make_low_pt_muon_line(
                forward_tracks,
                long_track_particles,
                name="Hlt1LowPtMuon" + name_suffix)))
    lines.append(
        line_maker(
            make_d2kk_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2KK" + name_suffix)))
    lines.append(
        line_maker(
            make_d2kpi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2KPi" + name_suffix)))
    lines.append(
        line_maker(
            make_d2pipi_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1D2PiPi" + name_suffix)))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonHighMass" + name_suffix)))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonLowMass" + name_suffix,
                pre_scaler_hash_string="di_muon_low_mass_line_pre" +
                name_suffix,
                post_scaler_hash_string="di_muon_low_mass_line_post" +
                name_suffix,
                minHighMassTrackPt=500.,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=4.)))
    lines.append(
        line_maker(
            make_di_muon_soft_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonSoft" + name_suffix)))
    lines.append(
        line_maker(
            make_low_pt_di_muon_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1LowPtDiMuon" + name_suffix)))
    lines.append(
        line_maker(
            make_track_muon_mva_line(
                forward_tracks,
                long_track_particles
                name="Hlt1TrackMuonMVA" + name_suffix)))
    return lines

def default_monitoring_lines(velo_tracks, name_suffix=''):
    lines = []
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1NoBeam" + name_suffix,
                beam_crossing_type=0,
                pre_scaler_hash_string="no_beam_line_pre" + name_suffix,
                post_scaler_hash_string="no_beam_line_post" + name_suffix)))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BeamOne" + name_suffix,
                beam_crossing_type=1,
                pre_scaler_hash_string="beam_one_line_pre" + name_suffix,
                post_scaler_hash_string="beam_one_line_post" + name_suffix)))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BeamTwo" + name_suffix,
                beam_crossing_type=2,
                pre_scaler_hash_string="beam_two_line_pre" + name_suffix,
                post_scaler_hash_string="beam_two_line_post" + name_suffix)))
    lines.append(
        line_maker(
            make_beam_line(
                name="Hlt1BothBeams" + name_suffix,
                beam_crossing_type=3,
                pre_scaler_hash_string="both_beams_line_pre" + name_suffix,
                post_scaler_hash_string="both_beams_line_post" + name_suffix)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINLumi" + name_suffix,
                odin_event_type=0x8,
                pre_scaler_hash_string="odin_lumi_line_pre" + name_suffix,
                post_scaler_hash_string="odin_lumi_line_post" + name_suffix)))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name="Hlt1ODINNoBias" + name_suffix,
                odin_event_type=0x4,
                pre_scaler_hash_string="odin_no_bias_pre" + name_suffix,
                post_scaler_hash_string="odin_no_bias_post" + name_suffix)))

    return lines

@configurable
def make_gec(gec_name='gec',
             min_scifi_ut_clusters="0",
             max_scifi_ut_clusters="9750"):
    return gec(
        name=gec_name,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)

@configurable
def make_checkPV(pvs, name='check_PV', minZ='-9999999', maxZ='99999999'):
    return checkPV(pvs, name=name, minZ=minZ, maxZ=maxZ)


@configurable
def make_lowmult(velo_tracks, minTracks='0', maxTracks='9999999'):
    return lowMult(velo_tracks, minTracks=minTracks, maxTracks=maxTracks)


def setup_hlt1_node(withMCChecking=False, EnableGEC=True):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()

    pp_checkPV = make_checkPV(
        reconstructed_objects['pvs'],
        name='pp_checkPV',
        minZ='-300'      , 
        maxZ='+300'      )

    pp_prefilters = [pp_checkPV]
    name_suffix = '_pp_checkPV'
    physics_lines = []

    if EnableGEC:
        gec = make_gec()
        pp_prefilters += [gec]
        name_suffix += '_gec'

    with line_maker.bind(prefilter=pp_prefilters):
        physics_lines = default_physics_lines(
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"],
            reconstructed_objects["secondary_vertices"])

    monitoring_lines = default_monitoring_lines(
        reconstructed_objects["velo_tracks"],
        reconstructed_objects["forward_tracks"],
        reconstructed_objects["long_track_particles"])

    with line_maker.bind(prefilter=None):
        physics_lines += [passthrough_line()]

    if EnableGEC:
        with line_maker.bind(prefilter=gec):
            physics_lines += [passthrough_line(name="Hlt1Passthrough_gec")]


    if EnableGEC:
        with line_maker.bind(prefilter = gec):
            monitoring_lines.append(
                line_maker(
                    make_velo_micro_bias_line(
                        reconstructed_objects["velo_tracks"],
                        name="Hlt1VeloMicroBias_gec") ))
            monitoring_lines.append(
                line_maker(
                    make_rich_1_line(
                        hlt1_reconstruction(), name="Hlt1RICH1Alignment_gec")))
            monitoring_lines.append(
                line_maker(
                    make_rich_2_line(
                        hlt1_reconstruction(), name="HLt1RICH2Alignment_gec")))

    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    lines = CompositeNode(
        "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    hlt1_node = CompositeNode(
        "Allen", [
            lines,
            make_global_decision(lines=line_algorithms),
            rate_validation(lines=line_algorithms),
            *make_sel_report_writer(
                lines=line_algorithms,
                forward_tracks=reconstructed_objects["long_track_particles"],
                secondary_vertices=reconstructed_objects["secondary_vertices"])
            ["algorithms"],
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    if not withMCChecking:
        return hlt1_node
    else:
        validation_node = validator_node(reconstructed_objects,
                                         line_algorithms)

        node = CompositeNode(
            "AllenWithValidators", [hlt1_node, validation_node],
            NodeLogic.NONLAZY_AND,
            force_order=False)

        return node
