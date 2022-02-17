###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.generator import make_algorithm
from AllenConf.algorithms import (host_init_number_of_events_t,
                                  host_data_provider_t,
                                  host_global_event_cut_t, layout_provider_t, 
                                  check_pvs_t, low_occupancy_t, odin_beamcrossingtype_t)


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
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t,
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


def checkPV( pvs, name = 'checkPV', minZ = "-999999", maxZ = "99999" ):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        check_pvs_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        #dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_multi_final_vertices_t=pvs["dev_multi_final_vertices"],
        dev_number_of_multi_final_vertices_t=pvs[
            "dev_number_of_multi_final_vertices"],
        minZ = minZ, maxZ = maxZ )


def lowMult( velo_tracks, name = 'LowMult', minTracks = "0", maxTracks = "99999" ):

    number_of_events = initialize_number_of_events()
    return make_algorithm(
        low_occupancy_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_velo_tracks_t=velo_tracks["host_number_of_reconstructed_velo_tracks"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_offsets_velo_tracks_t=velo_tracks["dev_offsets_all_velo_tracks"],
        dev_offsets_velo_track_hit_number_t=velo_tracks["dev_offsets_velo_track_hit_number"],
        minTracks=minTracks,
        maxTracks=maxTracks)


def ODIN_BeamXtype( name = 'ODIN_BeamXType', beam_type = "3"  ):

    number_of_events = initialize_number_of_events()
    layout = mep_layout()
    odin = decode_odin()

    return make_algorithm(
        odin_beamcrossingtype_t,
        name = name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        #dev_number_of_events_t=number_of_events["dev_number_of_events"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        beam_crossing_type = beam_type )
