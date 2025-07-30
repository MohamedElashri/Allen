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
from AllenCore.generator import make_algorithm, initialize_event_lists
from AllenCore.algorithms import (
    host_data_provider_t, host_scifi_gec_t, velo_clusters_gec_t, host_ut_gec_t,
    check_pvs_t, check_cyl_pvs_t, low_occupancy_t,
    check_localized_beamline_ip_t, error_bank_filter_t, data_provider_t,
    check_ecal_energy_t, velo_track_activity_filter_t,
    long_track_activity_filter_t, pv_activity_filter_t, prescaler_t)
from AllenConf.utils import initialize_number_of_events, mep_layout
from AllenConf.velo_reconstruction import decode_velo
from AllenConf.enum_types import ActivityType
from AllenConf.odin import decode_odin
from PyConf.tonic import configurable
from PyConf.control_flow import NodeLogic, CompositeNode


def ut_gec(name="ut_gec", min_clusters=0, max_clusters=9750):
    number_of_events = initialize_number_of_events()
    host_ut_banks = make_algorithm(
        host_data_provider_t, name="host_ut_banks", bank_type="UT")

    return make_algorithm(
        host_ut_gec_t,
        name=name,
        host_number_of_events_t=number_of_events['host_number_of_events'],
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
        host_ut_raw_sizes_t=host_ut_banks.host_raw_sizes_t,
        host_ut_raw_types_t=host_ut_banks.host_raw_types_t,
        host_ut_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t,
        min_clusters=min_clusters,
        max_clusters=max_clusters)


def scifi_gec(name="scifi_gec", min_clusters=0, max_clusters=20000):
    number_of_events = initialize_number_of_events()
    host_scifi_banks = make_algorithm(
        host_data_provider_t, name="host_scifi_banks", bank_type="FTCluster")

    return make_algorithm(
        host_scifi_gec_t,
        name=name,
        host_number_of_events_t=number_of_events['host_number_of_events'],
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t,
        host_scifi_raw_sizes_t=host_scifi_banks.host_raw_sizes_t,
        host_scifi_raw_types_t=host_scifi_banks.host_raw_types_t,
        min_clusters=min_clusters,
        max_clusters=max_clusters)


def velo_gec(name="velo_gec", min_clusters=0, max_clusters=35000):
    number_of_events = initialize_number_of_events()

    decoded_velo = decode_velo()

    return make_algorithm(
        velo_clusters_gec_t,
        name=name,
        host_number_of_events_t=number_of_events['host_number_of_events'],
        dev_offsets_velo_clusters_t=decoded_velo[
            'dev_offsets_estimated_input_size'],
        min_clusters=min_clusters,
        max_clusters=max_clusters)


@configurable
def make_gec(gec_name='gec',
             count_scifi=True,
             count_ut=False,
             count_velo=True,
             min_scifi_clusters=0,
             max_scifi_clusters=20000,
             min_ut_clusters=0,
             max_ut_clusters=9750,
             min_velo_clusters=0,
             max_velo_clusters=35000):
    algos = []
    if count_scifi:
        algos += [
            scifi_gec(
                'scifi_' + gec_name,
                min_clusters=min_scifi_clusters,
                max_clusters=max_scifi_clusters)
        ]
    if count_ut:
        algos += [
            ut_gec(
                'ut_' + gec_name,
                min_clusters=min_ut_clusters,
                max_clusters=max_ut_clusters)
        ]
    if count_velo:
        algos += [
            velo_gec(
                'velo_' + gec_name,
                min_clusters=min_velo_clusters,
                max_clusters=max_velo_clusters)
        ]

    return CompositeNode(
        gec_name + "_node", algos, NodeLogic.LAZY_AND, force_order=False)


def make_prescaler(value, name, hash_string=None):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()

    # Check for None or empty string
    if not hash_string:
        hash_string = f"{name}_pre"

    return make_algorithm(
        prescaler_t,
        name="prescaler_" + name,
        pre_scaler=value,
        pre_scaler_hash_string=hash_string,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_odin_data_t=odin['dev_odin_data'])


def long_track_activity_filter(long_tracks,
                               name="long_track_activity_filter",
                               min_long_tracks=1,
                               max_long_tracks=99999999):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        long_track_activity_filter_t,
        name=name,
        dev_long_tracks_view_t=long_tracks["dev_multi_event_long_tracks_view"],
        min_long_tracks=min_long_tracks,
        max_long_tracks=max_long_tracks)


def velo_track_activity_filter(velo_tracks,
                               name="velo_track_activity_filter",
                               min_velo_tracks=1,
                               max_velo_tracks=99999999):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        velo_track_activity_filter_t,
        name=name,
        host_number_of_events_t=number_of_events['host_number_of_events'],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        min_velo_tracks=min_velo_tracks,
        max_velo_tracks=max_velo_tracks)


@configurable
def make_pv_activity_filter(pvs,
                            name="pv_activity_filter",
                            min_pvs=1,
                            max_pvs=99999999):
    number_of_events = initialize_number_of_events()

    return make_algorithm(
        pv_activity_filter_t,
        name=name,
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        minPVs=min_pvs,
        maxPVs=max_pvs)


@configurable
def make_tae_activity_filter(
        long_tracks,
        velo_tracks,
        name="tae_activity_filter",
        use_long_tracks=True,  #if set to false, we use velo tracks instead
        min_tracks=1,
        max_tracks=99999999):

    if use_long_tracks:
        return long_track_activity_filter(
            long_tracks,
            name=name,
            min_long_tracks=min_tracks,
            max_long_tracks=max_tracks)

    else:
        return velo_track_activity_filter(
            velo_tracks,
            name=name,
            min_velo_tracks=min_tracks,
            max_velo_tracks=max_tracks)


@configurable
def make_minimal_activity_filter(reconstructed_objects, minimal_activity_type,
                                 min_activity, max_activity):

    activity_filter = []
    if minimal_activity_type is None:
        activity_filter = []
    elif minimal_activity_type is ActivityType.VELO_CLUSTERS:
        activity_filter = [
            make_gec(
                gec_name="minimal_activity_velo_clusters",
                count_velo=True,
                count_scifi=False,
                count_ut=False,
                min_velo_clusters=min_activity,
                max_velo_clusters=max_activity)
        ]
    elif minimal_activity_type is ActivityType.PRIMARY_VERTICES:
        activity_filter = [
            make_pv_activity_filter(
                reconstructed_objects["pvs"],
                min_pvs=min_activity,
                max_pvs=max_activity)
        ]
    elif minimal_activity_type is ActivityType.SCIFI_CLUSTERS:
        activity_filter = [
            make_gec(
                gec_name="minimal_activity_scifi_clusters",
                count_velo=False,
                count_scifi=True,
                count_ut=False,
                min_scifi_clusters=min_activity,
                max_scifi_clusters=max_activity)
        ]
    elif minimal_activity_type is ActivityType.VELO_TRACKS:
        activity_filter = [
            make_tae_activity_filter(
                reconstructed_objects["long_tracks"],
                reconstructed_objects["velo_tracks"],
                name="minimal_activity_velo_tracks",
                use_long_tracks=False,
                min_tracks=min_activity,
                max_tracks=max_activity)
        ]
    elif minimal_activity_type is ActivityType.LONG_TRACKS:
        activity_filter = [
            make_tae_activity_filter(
                reconstructed_objects["long_tracks"],
                reconstructed_objects["velo_tracks"],
                name="minimal_activity_long_tracks",
                use_long_tracks=True,
                min_tracks=min_activity,
                max_tracks=max_activity)
        ]
    else:
        raise Exception("Minimal activity type not supported")

    return activity_filter


@configurable
def make_checkPV(pvs, name='check_PV', min_z=-537.5, max_z=-337.5):
    return checkPV(pvs, name=name, minZ=min_z, maxZ=max_z)


@configurable
def make_checkCylPV(pvs,
                    name='check_PV',
                    min_vtx_z=-9999999.,
                    max_vtz_z=99999999.,
                    max_vtx_rho_sq=99999999.,
                    min_vtx_nTracks=1.):
    return checkCylPV(
        pvs,
        name=name,
        min_vtx_z=min_vtx_z,
        max_vtz_z=max_vtz_z,
        max_vtx_rho_sq=max_vtx_rho_sq,
        min_vtx_nTracks=min_vtx_nTracks)


@configurable
def make_checkPseudoPV(velo_states,
                       name='checkPseudoPVs',
                       min_state_z=-9999999.,
                       max_state_z=999999.,
                       max_state_rho_sq=999999.,
                       min_local_nTracks=10.):

    return checkPseudoPV(
        velo_states,
        name=name,
        min_state_z=min_state_z,
        max_state_z=max_state_z,
        max_state_rho_sq=max_state_rho_sq,
        min_local_nTracks=min_local_nTracks)


@configurable
def make_lowmult(velo_tracks,
                 calo,
                 name="lowMult",
                 minTracks=0,
                 maxTracks=9999999,
                 min_ecal_clusters=0,
                 max_ecal_clusters=9999999):
    return lowMult(
        velo_tracks,
        calo,
        name=name,
        minTracks=minTracks,
        maxTracks=maxTracks,
        min_ecal_clusters=min_ecal_clusters,
        max_ecal_clusters=max_ecal_clusters)


@configurable
def make_checkEcalEnergy(ecal_energy,
                         name='CheckEcalEnergy',
                         ecalCut=310000.,
                         cutHigh=True):
    return checkEcalEnergy(
        ecal_energy, name=name, ecalCut=ecalCut, cutHigh=cutHigh)


def checkPV(pvs, name='checkPV', minZ=-999999, maxZ=99999):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        check_pvs_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        minZ=minZ,
        maxZ=maxZ)


def checkCylPV(pvs,
               name='checkCylPV',
               min_vtx_z=-999999.,
               max_vtz_z=99999.,
               max_vtx_rho_sq=99999.,
               min_vtx_nTracks=10.):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        check_cyl_pvs_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        min_vtx_z=min_vtx_z,
        max_vtz_z=max_vtz_z,
        max_vtx_rho_sq=max_vtx_rho_sq,
        min_vtx_nTracks=min_vtx_nTracks)


def checkPseudoPV(velo_states,
                  name='checkPseudoPVs',
                  min_state_z=-999999.,
                  max_state_z=99999.,
                  max_state_rho_sq=99999.,
                  min_local_nTracks=10.):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        check_localized_beamline_ip_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_velo_states_view_t=velo_states[
            'dev_velo_kalman_beamline_states_view'],
        min_state_z=min_state_z,
        max_state_z=max_state_z,
        max_state_rho_sq=max_state_rho_sq,
        min_local_nTracks=min_local_nTracks)


def lowMult(velo_tracks,
            calo,
            name='LowMult',
            minTracks=0,
            maxTracks=99999,
            min_ecal_clusters=0,
            max_ecal_clusters=999999):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        low_occupancy_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        host_ecal_number_of_clusters_t=calo["host_ecal_number_of_clusters"],
        dev_ecal_cluster_offsets_t=calo["dev_ecal_cluster_offsets"],
        minTracks=minTracks,
        maxTracks=maxTracks,
        min_ecal_clusters=min_ecal_clusters,
        max_ecal_clusters=max_ecal_clusters)


def checkEcalEnergy(ecal_energy,
                    name='CheckEcalEnergy',
                    ecalCut=310000.,
                    cutHigh=True):
    number_of_events = initialize_number_of_events()
    return make_algorithm(
        check_ecal_energy_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_total_ecal_e_t=ecal_energy,
        ecalCut=ecalCut,
        cutHigh=cutHigh)


def sd_error_filter():
    number_of_events = initialize_number_of_events()
    event_list = initialize_event_lists()
    layout = mep_layout()

    bank_types = {
        "ODIN": {
            "data_types": ["ODIN"]
        },
        "VP": {
            "data_types": ["VP", "VPRetinaCluster"],
            "error_types": ["VeloError"]
        },
        "UT": {
            "data_types": ["UT", "UTFull"],
            "other_types": ["UTPedestal", "UTNZS", "UTSpecial"],
            "error_types": ["UTError"]
        },
        "Rich1": {
            "data_types": ["Rich"],
            "other_types": ["RichCommissioning"],
            "error_types": ["RichError"]
        },
        "FTCluster": {
            "data_types": ["FTCluster"],
            "other_types":
            ["FTGeneric", "FTCalibration", "FTNZS", "FTSpecial"],
            "error_types": ["FTError"]
        },
        "Rich2": {
            "data_types": ["Rich"],
            "other_types": ["RichCommissioning"],
            "error_types": ["RichError"]
        },
        "ECal": {
            "data_types": ["Calo"],
            "other_types": ["CaloSpecial"],
            "error_types": ["CaloError"]
        },
        "HCal": {
            "data_types": ["Calo"],
            "other_types": ["CaloSpecial"],
            "error_types": ["CaloError"]
        },
        "Muon": {
            "data_types": ["Muon", "MuonFull"],
            "other_types": ["MuonSpecial"],
            "error_types": ["MuonError"]
        },
        "Plume": {
            "data_types": ["Plume"],
            "other_types": ["PlumeSpecial"],
            "error_types": ["PlumeError"]
        }
    }

    daq_error_types = [
        "DaqErrorFragmentThrottled", "DaqErrorBXIDCorrupted",
        "DaqErrorSyncBXIDCorrupted", "DaqErrorFragmentMissing",
        "DaqErrorFragmentTruncated", "DaqErrorIdleBXIDCorrupted",
        "DaqErrorFragmentMalformed", "DaqErrorEVIDJumped",
        "DaqErrorAlignFifoFull", "DaqErrorFEfragSizeWrong"
    ]

    return make_algorithm(
        error_bank_filter_t,
        name="error_bank_filter",
        host_event_list_t=event_list.host_event_list_output_t,
        mep_layout_t=layout['host_mep_layout'],
        sd_bank_types=bank_types,
        daq_error_types=daq_error_types)
