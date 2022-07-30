###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.generator import make_algorithm
from AllenAlgorithms.algorithms import (
    host_init_number_of_events_t, host_data_provider_t,
    host_global_event_cut_t, layout_provider_t, check_pvs_t, low_occupancy_t)
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


@configurable
def make_gec(gec_name='gec',
             min_scifi_ut_clusters=0,
             max_scifi_ut_clusters=9750):
    return gec(
        name=gec_name,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters)


@configurable
def make_checkPV(pvs, name='check_PV', minZ=-9999999, maxZ=99999999):
    return checkPV(pvs, name=name, minZ=minZ, maxZ=maxZ)


@configurable
def make_lowmult(velo_tracks, name="lowMult", minTracks=0, maxTracks=9999999):
    return lowMult(
        velo_tracks, name=name, minTracks=minTracks, maxTracks=maxTracks)


def initialize_number_of_events():
    initialize_number_of_events = make_algorithm(
        host_init_number_of_events_t, name="initialize_number_of_events")
    return {
        "host_number_of_events":
        initialize_number_of_events.host_number_of_events_t,
        "dev_number_of_events":
        initialize_number_of_events.dev_number_of_events_t,
    }


def gec(name="gec", min_scifi_ut_clusters=0, max_scifi_ut_clusters=9750):
    number_of_events = initialize_number_of_events()

    host_ut_banks = make_algorithm(
        host_data_provider_t, name="host_ut_banks", bank_type="UT")

    host_scifi_banks = make_algorithm(
        host_data_provider_t, name="host_scifi_banks", bank_type="FTCluster")

    gec = make_algorithm(
        host_global_event_cut_t,
        name=name,
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
        host_ut_raw_sizes_t=host_ut_banks.host_raw_sizes_t,
        host_ut_raw_types_t=host_ut_banks.host_raw_types_t,
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t,
        host_scifi_raw_sizes_t=host_scifi_banks.host_raw_sizes_t,
        host_scifi_raw_types_t=host_scifi_banks.host_raw_types_t,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters,
        host_ut_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t)

    return gec


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


def lowMult(velo_tracks, name='LowMult', minTracks=0, maxTracks=99999):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        low_occupancy_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks[
            "host_number_of_reconstructed_velo_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks[
            "dev_offsets_velo_track_hit_number"],
        minTracks=minTracks,
        maxTracks=maxTracks)
