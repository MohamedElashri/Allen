###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *


def MuonSequence(initialize_lists, prefix_sum_forward_tracks,
                 prefix_sum_scifi_track_hit_number,
                 scifi_consolidate_tracks_t):

    muon_banks = data_provider_t(name="muon_banks", bank_type="Muon")

    muon_calculate_srq_size = muon_calculate_srq_size_t(
        host_number_of_events_t=initialize_lists.
        host_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_muon_raw_t=muon_banks.dev_raw_banks_t(),
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t())

    muon_srq_prefix_sum = host_prefix_sum_t(
        name="muon_srq_prefix_sum",
        dev_input_buffer_t=muon_calculate_srq_size.
        dev_storage_station_region_quarter_sizes_t(),
    )

    muon_populate_tile_and_tdc = muon_populate_tile_and_tdc_t(
        host_number_of_events_t=initialize_lists.
        host_number_of_events_t(),
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_muon_raw_t=muon_banks.dev_raw_banks_t(),
        dev_muon_raw_offsets_t=muon_banks.dev_raw_offsets_t(),
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.
        dev_muon_raw_to_hits_t(),
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t())

    muon_add_coords_crossing_maps = muon_add_coords_crossing_maps_t(
        host_number_of_events_t=initialize_lists.
        host_number_of_events_t(),
        host_muon_total_number_of_tiles_t=muon_srq_prefix_sum.
        host_total_sum_holder_t(),
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t(),
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.
        dev_storage_tile_id_t(),
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.
        dev_muon_raw_to_hits_t())

    muon_station_ocurrence_prefix_sum = host_prefix_sum_t(
        name="muon_station_ocurrence_prefix_sum",
        dev_input_buffer_t=muon_add_coords_crossing_maps.
        dev_station_ocurrences_sizes_t())

    muon_populate_hits = muon_populate_hits_t(
        host_number_of_events_t=initialize_lists.
        host_number_of_events_t(),
        host_muon_total_number_of_hits_t=muon_station_ocurrence_prefix_sum.
        host_total_sum_holder_t(),
        dev_storage_tile_id_t=muon_populate_tile_and_tdc.
        dev_storage_tile_id_t(),
        dev_storage_tdc_value_t=muon_populate_tile_and_tdc.
        dev_storage_tdc_value_t(),
        dev_station_ocurrences_offset_t=muon_station_ocurrence_prefix_sum.
        dev_output_buffer_t(),
        dev_muon_compact_hit_t=muon_add_coords_crossing_maps.
        dev_muon_compact_hit_t(),
        dev_muon_raw_to_hits_t=muon_calculate_srq_size.
        dev_muon_raw_to_hits_t(),
        dev_storage_station_region_quarter_offsets_t=muon_srq_prefix_sum.
        dev_output_buffer_t())

    is_muon = is_muon_t(
        host_number_of_events_t=initialize_lists.
        host_number_of_events_t(),
        host_number_of_reconstructed_scifi_tracks_t=prefix_sum_forward_tracks.
        host_total_sum_holder_t(),
        dev_offsets_forward_tracks_t=prefix_sum_forward_tracks.
        dev_output_buffer_t(),
        dev_offsets_scifi_track_hit_number=prefix_sum_scifi_track_hit_number.
        dev_output_buffer_t(),
        dev_scifi_qop_t=scifi_consolidate_tracks_t.dev_scifi_qop_t(),
        dev_scifi_states_t=scifi_consolidate_tracks_t.dev_scifi_states_t(),
        dev_scifi_track_ut_indices_t=scifi_consolidate_tracks_t.
        dev_scifi_track_ut_indices_t(),
        dev_station_ocurrences_offset_t=muon_station_ocurrence_prefix_sum.
        dev_output_buffer_t(),
        dev_muon_hits_t=muon_populate_hits.dev_muon_hits_t())

    return Sequence(muon_banks, muon_calculate_srq_size, muon_srq_prefix_sum,
                    muon_populate_tile_and_tdc, muon_add_coords_crossing_maps,
                    muon_station_ocurrence_prefix_sum, muon_populate_hits,
                    is_muon)
