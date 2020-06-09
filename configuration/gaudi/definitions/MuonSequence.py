from PyConf.components import Algorithm
from algorithms import *
from ForwardSequence import make_forward_tracks
from VeloSequence import initialize_lists


def is_muon(**kwargs):
    initalized_lists = initialize_lists(**kwargs)
    host_number_of_selected_events = initalized_lists[
        "host_number_of_selected_events"]
    dev_event_list = initalized_lists["dev_event_list"]

    forward_tracks = make_forward_tracks(**kwargs)
    host_number_of_reconstructed_scifi_tracks = forward_tracks[
        "host_number_of_reconstructed_scifi_tracks"]
    dev_offsets_forward_tracks = forward_tracks["dev_offsets_forward_tracks"]
    dev_offsets_scifi_track_hit_number = forward_tracks[
        "dev_offsets_scifi_track_hit_number"]
    dev_scifi_qop = forward_tracks["dev_scifi_qop"]
    dev_scifi_states = forward_tracks["dev_scifi_states"]
    dev_scifi_track_ut_indices = forward_tracks["dev_scifi_track_ut_indices"]

    muon_banks = Algorithm(
        data_provider_t, name="muon_banks", bank_type="Muon")

    muon_calculate_srq_size = Algorithm(
        muon_calculate_srq_size_t,
        name="muon_calculate_srq_size",
        host_number_of_selected_events_t=host_number_of_selected_events,
        dev_event_list_t=dev_event_list,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t)

    muon_srq_prefix_sum = Algorithm(
        host_prefix_sum_t,
        name="muon_srq_prefix_sum",
        dev_input_buffer_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_sizes_t,
    )

    muon_populate_tile_and_tdc = Algorithm(
        muon_populate_tile_and_tdc_t,
        name="muon_populate_tile_and_tdc",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t,
        dev_event_list_t=dev_event_list,
        dev_muon_raw_t=muon_banks.dev_raw_banks_t,
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t,
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.dev_muon_raw_to_hits_t,
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t)

    muon_add_coords_crossing_maps = Algorithm(
        muon_add_coords_crossing_maps_t,
        name="muon_add_coords_crossing_maps",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t,
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t,
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.dev_storage_tile_id_t,
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.dev_muon_raw_to_hits_t)

    muon_station_ocurrence_prefix_sum = Algorithm(
        host_prefix_sum_t,
        name="muon_station_ocurrence_prefix_sum",
        dev_input_buffer_t=muon_add_coords_crossing_maps.
        dev_station_ocurrences_sizes_t)

    muon_populate_hits = Algorithm(
        muon_populate_hits_t,
        name="muon_populate_hits",
        host_number_of_selected_events_t=host_number_of_selected_events,
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

    is_muon = Algorithm(
        is_muon_t,
        name="is_muon",
        host_number_of_selected_events_t=host_number_of_selected_events,
        host_number_of_reconstructed_scifi_tracks_t=
        host_number_of_reconstructed_scifi_tracks,
        dev_offsets_forward_tracks_t=dev_offsets_forward_tracks,
        dev_offsets_scifi_track_hit_number=dev_offsets_scifi_track_hit_number,
        dev_scifi_qop_t=dev_scifi_qop,
        dev_scifi_states_t=dev_scifi_states,
        dev_scifi_track_ut_indices_t=dev_scifi_track_ut_indices,
        dev_station_ocurrences_offset_t=muon_station_ocurrence_prefix_sum.
        dev_output_buffer_t,
        dev_muon_hits_t=muon_populate_hits.dev_muon_hits_t)

    return {
        "dev_muon_track_occupancies": is_muon.dev_muon_track_occupancies_t,
        "dev_is_muon": is_muon.dev_is_muon_t
    }
