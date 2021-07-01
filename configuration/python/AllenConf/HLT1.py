
###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.utils import initialize_number_of_events, mep_layout, gec, checkPV, lowMult
from AllenConf.hlt1_reconstruction import hlt1_reconstruction, validator_node
from AllenConf.hlt1_inclusive_hadron_lines import make_track_mva_line, make_two_track_mva_line, make_kstopipi_line, make_two_track_line_ks
from AllenConf.hlt1_charm_lines import make_d2kk_line, make_d2pipi_line, make_two_ks_line
from AllenConf.hlt1_calibration_lines import make_d2kpi_line, make_passthrough_line, make_rich_1_line, make_rich_2_line
from AllenConf.hlt1_muon_lines import make_single_high_pt_muon_line, make_single_high_pt_muon_no_muid_line, make_low_pt_muon_line, make_di_muon_mass_line, make_di_muon_soft_line, make_low_pt_di_muon_line, make_track_muon_mva_line
from AllenConf.hlt1_electron_lines import make_track_electron_mva_line, make_single_high_pt_electron_line, make_displaced_dielectron_line, make_displaced_leptons_line, make_single_high_et_line
from AllenConf.hlt1_monitoring_lines import make_beam_line, make_velo_micro_bias_line, make_odin_event_type_line, make_beam_gas_line
from AllenConf.hlt1_smog2_lines import ( make_SMOG2_minimum_bias_line, make_SMOG2_dimon_highmass_line, 
                                         make_SMOG2_ditrack_line, make_SMOG2_singletrack_line )


from AllenConf.validators import rate_validation
from AllenCore.generator import make_algorithm
from PyConf.control_flow import NodeLogic, CompositeNode
from PyConf.tonic import configurable
from AllenConf.odin import decode_odin
from AllenConf.persistency import make_global_decision, make_sel_report_writer

# Helper function to make composite nodes
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

def passthrough_line( name = 'Hlt1Passthrough' ):
    return line_maker(
        make_passthrough_line(
            name=name,
            pre_scaler_hash_string = name + "_line_pre",
            post_scaler_hash_string= name + "_line_post") )
        


def default_physics_lines(velo_tracks, forward_tracks, long_track_particles,
                          secondary_vertices, calo_matching_objects, name_suffix = ''):

    lines = [passthrough_line( name = 'Hlt1Passthrough' + name_suffix)]
    lines.append(
        line_maker(
            "Hlt1KsToPiPi" + name_suffix,
            make_kstopipi_line(forward_tracks, secondary_vertices),
            enableGEC=True))
    lines.append(
        line_maker("Hlt1TrackMVA",
                   make_track_mva_line(forward_tracks, long_track_particles)))
    lines.append(
        line_maker("Hlt1TwoTrackMVA",
                   make_two_track_mva_line(forward_tracks,
                                           secondary_vertices)))
    lines.append(
        line_maker("Hlt1TwoTrackKs",
                   make_two_track_line_ks(forward_tracks, secondary_vertices)))
    lines.append(
        line_maker(
            "Hlt1SingleHighPtMuon",
            make_single_high_pt_muon_line(forward_tracks,
                                          long_track_particles)))
    lines.append(
        line_maker(
            make_single_high_pt_muon_no_muid_line(forward_tracks,
                                                  long_track_particles, 
                                                  name = "Hlt1SingleHighPtMuonNoMuID" + prefilter_suffix)))
    lines.append(
            make_low_pt_muon_line(
                forward_tracks, long_track_particles, name = "Hlt1LowPtMuon" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_d2kk_line(
                forward_tracks, secondary_vertices, name = "Hlt1D2KK" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_d2kpi_line(
                forward_tracks, secondary_vertices, name = "Hlt1D2KPi" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_d2pipi_line(
                forward_tracks, secondary_vertices, name = "Hlt1D2PiPi" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_di_muon_mass_line(
                forward_tracks, secondary_vertices, name = "Hlt1DiMuonHighMass" + name_suffix),
        ))
    lines.append(
        line_maker(
            "Hlt1DiMuonLowMass",
            make_di_muon_mass_line(
                forward_tracks,
                secondary_vertices,
                name="Hlt1DiMuonLowMass" + name_suffix,
                pre_scaler_hash_string="di_muon_low_mass_line_pre" + name_suffix,
                post_scaler_hash_string="di_muon_low_mass_line_post" + name_suffix,
                minHighMassTrackPt=500.,
                minHighMassTrackP=3000.,
                minMass=0.,
                maxDoca=0.2,
                maxVertexChi2=25.,
                minIPChi2=4.),
        ))
    lines.append(
        line_maker(
            make_di_muon_soft_line(
                forward_tracks, secondary_vertices, name = "Hlt1DiMuonSoft" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_low_pt_di_muon_line(
                forward_tracks, secondary_vertices, name = "Hlt1LowPtDiMuon" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_track_muon_mva_line(forward_tracks, long_track_particles, name = "Hlt1TrackMuonMVA" + name_suffix )
        ))

    return lines


def default_monitoring_lines(velo_tracks, forward_tracks,
                             long_track_particles, velo_states, name_suffix = ''):
    lines = []
    lines.append(
        line_maker(
            make_beam_line(
                name = "Hlt1NoBeam" + name_suffix,
                beam_crossing_type=0, 
                pre_scaler_hash_string="no_beam_line_pre" + name_suffix,
                post_scaler_hash_string="no_beam_line_post" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_beam_line(
                name = "Hlt1BeamOne" + name_suffix,
                beam_crossing_type=1,
                pre_scaler_hash_string="beam_one_line_pre" + name_suffix,
                post_scaler_hash_string="beam_one_line_post" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_beam_line(
                name = "Hlt1BeamTwo" + name_suffix,
                beam_crossing_type=2,
                pre_scaler_hash_string="beam_two_line_pre" + name_suffix,
                post_scaler_hash_string="beam_two_line_post" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_beam_line(
                name = "Hlt1BothBeams" + name_suffix,
                beam_crossing_type=3,
                pre_scaler_hash_string="both_beams_line_pre" + name_suffix,
                post_scaler_hash_string="both_beams_line_post" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name = "Hlt1ODINLumi" + name_suffix,
                odin_event_type=0x8,
                pre_scaler_hash_string="odin_lumi_line_pre" + name_suffix,
                post_scaler_hash_string="odin_lumi_line_post" + name_suffix),
        ))
    lines.append(
        line_maker(
            make_odin_event_type_line(
                name = "Hlt1ODINNoBias" + name_suffix,
                odin_event_type=0x4,
                pre_scaler_hash_string="odin_no_bias_pre" + name_suffix,
                post_scaler_hash_string="odin_no_bias_post" + name_suffix),
            enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1Passthrough", make_passthrough_line(), enableGEC=False))
    lines.append(
        line_maker(
            "Hlt1RICH1Alignment",
            make_rich_1_line(forward_tracks, long_track_particles),
            enableGEC=True))
    lines.append(
        line_maker(
            "HLt1RICH2Alignment",
            make_rich_2_line(forward_tracks, long_track_particles),
            enableGEC=True))
    lines.append(
        line_maker(
            "Hlt1BeamGas",
            make_beam_gas_line(
                velo_tracks,
                velo_states,
                pre_scaler_hash_string="no_beam_line_pre",
                post_scaler_hash_string="no_beam_line_post",
                beam_crossing_type=1),
            enableGEC=True))

    return lines


def default_smog2_lines( velo_tracks, velo_states, pvs, forward_tracks, 
                         long_track_particles, secondary_vertices, name_suffix = ''):

    smog2_lines = [ passthrough_line( name = "Hlt1Passthrough_SMOG2" + name_suffix) ]

    smog2_lines.append(
        line_maker(
            make_SMOG2_minimum_bias_line(
                velo_tracks, velo_states, name = "HLT1_SMOG2_MinimumBiasLine" + name_suffix ),
                ))

    smog2_lines.append(
        line_maker(
            make_SMOG2_dimon_highmass_line( 
                secondary_vertices, name =  "HLT1_SMOG2_DiMuonHighMassLine" + name_suffix ),
        ))

    smog2_lines.append(
        line_maker( 
            make_SMOG2_ditrack_line( 
                secondary_vertices, m1 = "139.57f", m2 = "493.67f",
                mMother = "1864.83f", name = "HLT1_SMOG2_D2Kpi" + name_suffix ),
        ))

    smog2_lines.append(
        line_maker( 
            make_SMOG2_ditrack_line( 
                secondary_vertices, m1 = "938.27f", m2 = "938.27f",
                mMother = "2983.6", name = "HLT1_SMOG2_eta2pp" + name_suffix ),
        ))

    smog2_lines.append(
        line_maker( 
            make_SMOG2_ditrack_line(
                secondary_vertices, minTrackPt = 800, name = "HLT1_SMOG2_2BodyGeneric" + name_suffix ),
                   ))

    smog2_lines.append(
        line_maker( 
            make_SMOG2_singletrack_line( 
                forward_tracks, long_track_particles, name = "HLT1_SMOG2_SingleTrack" + name_suffix ),
        ))

    return smog2_lines


@configurable
def make_gec(gec_name='gec',
             min_scifi_ut_clusters="0",
             max_scifi_ut_clusters="9750"):
    return gec(
        name=gec_name,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)

@configurable
def make_checkPV(pvs, name='check_PV', minZ='-9999999', maxZ= '99999999'):
    return checkPV(pvs, name=name, minZ=minZ, maxZ=maxZ)

@configurable
def make_lowmult(velo_tracks, minTracks = '0', maxTracks = '9999999'):
    return lowMult( velo_tracks, minTracks = minTracks, maxTracks = maxTracks)


def setup_hlt1_node(withMCChecking=False, EnableGEC=True, withSMOG2=False):
    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction(add_electron_id=True)

    pp_prefilters = [
        make_checkPV(
            reconstructed_objects['pvs'],
            name='pp_checkPV',
            minZ='-300',
            maxZ='300') ]
    name_suffix = '_pp_checkPV'
    physics_lines = []

    if EnableGEC: 
        with line_maker.bind( prefilter = None):
            physics_lines += [ passthrough_line() ]

        gec = make_gec()         
        with line_maker.bind( prefilter = gec):
            physics_lines += [ passthrough_line( name = "Hlt1Passthrough_gec") ]
        
        pp_prefilters += [ gec ]
        name_suffix += '_gec'

        
    with line_maker.bind(prefilter=pp_prefilters):
        physics_lines += default_physics_lines(
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"],
            reconstructed_objects["secondary_vertices"],
            reconstructed_objects["calo_matching_objects"], 
            name_suffix = name_suffix)

    monitoring_lines = default_monitoring_lines(
        reconstructed_objects["velo_tracks"],
        reconstructed_objects["forward_tracks"],
        reconstructed_objects["long_track_particles"],
        reconstructed_objects["velo_states"])

    monitoring_lines.append( line_maker(
        make_velo_micro_bias_line(reconstructed_objects["velo_tracks"], name = "Hlt1VeloMicroBias_gec"),
        prefilter = [gec] ) )

    #physics_lines, monitoring_lines = [], []
    # list of line algorithms, required for the gather selection and DecReport algorithms
    line_algorithms = [tup[0] for tup in physics_lines
                       ] + [tup[0] for tup in monitoring_lines]
    # lost of line nodes, required to set up the CompositeNode
    line_nodes = [tup[1] for tup in physics_lines
                  ] + [tup[1] for tup in monitoring_lines]

    if withSMOG2:        
        SMOG2_prefilters = [        
            make_checkPV(
                reconstructed_objects['pvs'],
                name='check_SMOG2_PV',
                minZ='-500',  #mm
                maxZ='-300'   #mm
            )]
        name_suffix = '_SMOG2_checkPV'
        if EnableGEC: 
            SMOG2_prefilters += [ gec ]
            name_suffix += '_gec' 

        lowMult_5 = make_lowmult( reconstructed_objects['velo_tracks'], minTracks = '1', maxTracks = '5') 
        with line_maker.bind( prefilter = lowMult_5):
            smog2_lines = [ passthrough_line( name = "Hlt1PassThrough_LowMult")]
            
 
        with line_maker.bind( prefilter = SMOG2_prefilters) :
            smog2_lines += default_smog2_lines(
                reconstructed_objects["velo_tracks"],
                reconstructed_objects["velo_states"], 
                reconstructed_objects["pvs"],         
                reconstructed_objects["forward_tracks"],        
                reconstructed_objects["kalman_velo_only"],      
                reconstructed_objects["secondary_vertices"], 
                name_suffix = name_suffix )
        
        line_algorithms += [ tup[0] for tup in smog2_lines ]
        line_nodes      += [ tup[1] for tup in smog2_lines ]

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
