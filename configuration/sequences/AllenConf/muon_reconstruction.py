###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenConf.algorithms import (
    data_provider_t, muon_calculate_srq_size_t, host_prefix_sum_t,
    muon_populate_tile_and_tdc_t, muon_add_coords_crossing_maps_t,
    muon_populate_hits_t, is_muon_t)
from AllenConf.utils import initialize_number_of_events
from AllenCore.event_list_utils import make_algorithm

def decode_muon():
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    muon_banks = make_algorithm(
        data_provider_t, name="muon_banks", bank_type="Muon")

    muon_calculate_srq_size = make_algorithm(
        muon_calculate_srq_size_t,
        name="muon_calculate_srq_size",
        host_number_of_events_t=host_number_of_events,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t)

    muon_srq_prefix_sum = make_algorithm(
        host_prefix_sum_t,
        name="muon_srq_prefix_sum",
        dev_input_buffer_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_sizes_t,
    )

    muon_populate_tile_and_tdc = make_algorithm(
        muon_populate_tile_and_tdc_t,
        name="muon_populate_tile_and_tdc",
        host_number_of_events_t=host_number_of_events,
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t,
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.dev_muon_raw_to_hits_t,
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t)

    muon_add_coords_crossing_maps = make_algorithm(
        muon_add_coords_crossing_maps_t,
        name="muon_add_coords_crossing_maps",
        host_number_of_events_t=host_number_of_events,
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t,
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t,
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.dev_storage_tile_id_t,
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.dev_muon_raw_to_hits_t)

    muon_station_ocurrence_prefix_sum = make_algorithm(
        host_prefix_sum_t,
        name="muon_station_ocurrence_prefix_sum",
        dev_input_buffer_t=muon_add_coords_crossing_maps.
        dev_station_ocurrences_sizes_t)

    muon_populate_hits = make_algorithm(
        muon_populate_hits_t,
        name="muon_populate_hits",
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_muon_total_number_of_hits_t=muon_station_ocurrence_prefix_sum.
        host_total_sum_holder_t,
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.dev_storage_tile_id_t,
        dev_storage_tdc_value_t=muon_populate_tile_and_tdc.
        dev_storage_tdc_value_t,
        dev_station_ocurrences_offset_t=muon_station_ocurrence_prefix_sum.
        dev_output_buffer_t,
        dev_muon_compact_hit_t=muon_add_coords_crossing_maps.
        dev_muon_compact_hit_t,
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.dev_muon_raw_to_hits_t,
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t)

    return {
        "dev_muon_hits":
        muon_populate_hits.dev_muon_hits_t,
        "dev_station_ocurrences_offset":
        muon_station_ocurrence_prefix_sum.dev_output_buffer_t
    }


def is_muon(decoded_muon, forward_tracks):
    number_of_events = initialize_number_of_events()
    host_number_of_events = number_of_events["host_number_of_events"]
    dev_number_of_events = number_of_events["dev_number_of_events"]

    host_number_of_reconstructed_scifi_tracks = forward_tracks[
        "host_number_of_reconstructed_scifi_tracks"]
    dev_offsets_forward_tracks = forward_tracks["dev_offsets_forward_tracks"]
    dev_offsets_scifi_track_hit_number = forward_tracks[
        "dev_offsets_scifi_track_hit_number"]
    dev_scifi_qop = forward_tracks["dev_scifi_qop"]
    dev_scifi_states = forward_tracks["dev_scifi_states"]
    dev_scifi_track_ut_indices = forward_tracks["dev_scifi_track_ut_indices"]

    is_muon = make_algorithm(
        is_muon_t,
        name="is_muon",
        host_number_of_events_t=host_number_of_events,
        dev_number_of_events_t=dev_number_of_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_offsets_forward_tracks_t=dev_offsets_forward_tracks,
        dev_offsets_scifi_track_hit_number=dev_offsets_scifi_track_hit_number,
        dev_scifi_qop_t=dev_scifi_qop,
        dev_scifi_states_t=dev_scifi_states,
        dev_scifi_track_ut_indices_t=dev_scifi_track_ut_indices,
        dev_station_ocurrences_offset_t=decoded_muon[
            "dev_station_ocurrences_offset"],
        dev_muon_hits_t=decoded_muon["dev_muon_hits"])

    return {
        "forward_tracks": forward_tracks,
        "dev_muon_track_occupancies": is_muon.dev_muon_track_occupancies_t,
        "dev_is_muon": is_muon.dev_is_muon_t
    }

def muon_id():
    from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
    from AllenConf.ut_reconstruction import decode_ut, make_ut_tracks 
    from AllenConf.scifi_reconstruction import decode_scifi, make_forward_tracks
    
    decoded_velo = decode_velo()
    velo_tracks = make_velo_tracks(decoded_velo)
    decoded_ut = decode_ut()
    ut_tracks = make_ut_tracks(decoded_ut, velo_tracks)
    decoded_scifi = decode_scifi()
    forward_tracks = make_forward_tracks(decoded_scifi, ut_tracks)
    decoded_muon = decode_muon()
    muonID = is_muon(decoded_muon, forward_tracks)
    alg = muonID["dev_is_muon"].producer
    return alg
 
