###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.generator import make_algorithm
from AllenCore.algorithms import (
    host_init_number_of_events_t, host_data_provider_t, host_scifi_gec_t,
    host_ut_gec_t, layout_provider_t, check_pvs_t, check_cyl_pvs_t,
    low_occupancy_t, event_list_inversion_t, host_dummy_maker_t)
from PyConf.tonic import configurable
from PyConf.control_flow import NodeLogic, CompositeNode


# Helper function to make composite nodes
def make_line_composite_node(name, algos):
    return CompositeNode(
        name + "_node", algos, NodeLogic.LAZY_AND, force_order=True)


@configurable
def line_maker(line_algorithm, prefilter=None):
    #add odin error filter by default
    if prefilter is None:
        node = make_line_composite_node(
            line_algorithm.name, algos=[line_algorithm])
    elif isinstance(prefilter, list):
        node = make_line_composite_node(
            line_algorithm.name, algos=prefilter + [line_algorithm])
    else:
        node = make_line_composite_node(
            line_algorithm.name, algos=[prefilter, line_algorithm])
    return line_algorithm, node


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


def scifi_gec(name="scifi_gec", min_clusters=0, max_clusters=9750):
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


@configurable
def make_gec(gec_name='gec',
             count_scifi=True,
             count_ut=True,
             min_scifi_clusters=0,
             max_scifi_clusters=9750,
             min_ut_clusters=0,
             max_ut_clusters=9750):
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

    return CompositeNode(
        gec_name + "_node", algos, NodeLogic.LAZY_AND, force_order=False)


@configurable
def make_checkPV(pvs, name='check_PV', minZ=-9999999, maxZ=99999999):
    return checkPV(pvs, name=name, minZ=minZ, maxZ=maxZ)


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
def make_lowmult(velo_tracks, name="lowMult", minTracks=0, maxTracks=9999999):
    return lowMult(
        velo_tracks, name=name, minTracks=minTracks, maxTracks=maxTracks)


def make_invert_event_list(
        alg, name, alg_output_event_list_name="dev_event_list_output_t"):
    return make_algorithm(
        event_list_inversion_t,
        name=name,
        dev_event_list_input_t=getattr(alg, alg_output_event_list_name))


def initialize_number_of_events():
    initialize_number_of_events = make_algorithm(
        host_init_number_of_events_t, name="initialize_number_of_events")
    return {
        "host_number_of_events":
        initialize_number_of_events.host_number_of_events_t,
        "dev_number_of_events":
        initialize_number_of_events.dev_number_of_events_t,
    }


def mep_layout():
    layout = make_algorithm(layout_provider_t, name="mep_layout")
    return {
        "host_mep_layout": layout.host_mep_layout_t,
        "dev_mep_layout": layout.dev_mep_layout_t
    }


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


def lowMult(velo_tracks, name='LowMult', minTracks=0, maxTracks=99999):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        low_occupancy_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        minTracks=minTracks,
        maxTracks=maxTracks)


def make_dummy():
    return make_algorithm(host_dummy_maker_t, name="host_dummy_maker")
