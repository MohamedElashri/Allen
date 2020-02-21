from algorithms import *


def Muon_sequence(validate=False):
    muon_pre_decoding = muon_pre_decoding_t()

    muon_pre_decoding_prefix_sum = host_prefix_sum_t(
        "muon_pre_decoding_prefix_sum",
        host_total_sum_holder_t="host_muon_total_number_of_tiles_t",
        dev_input_buffer_t=muon_pre_decoding.
        dev_storage_station_region_quarter_sizes_t(),
        dev_output_buffer_t="dev_storage_station_region_quarter_offsets_t")

    muon_sort_station_region_quarter = muon_sort_station_region_quarter_t()
    muon_add_coords_crossing_maps = muon_add_coords_crossing_maps_t()

    muon_station_ocurrence_prefix_sum = host_prefix_sum_t(
        "muon_station_ocurrence_prefix_sum",
        host_total_sum_holder_t="host_muon_total_number_of_hits_t",
        dev_input_buffer_t=muon_add_coords_crossing_maps.
        dev_station_ocurrences_sizes_t(),
        dev_output_buffer_t="dev_station_ocurrences_offset_t")

    muon_sort_by_station = muon_sort_by_station_t()
    is_muon = is_muon_t()

    muon_sequence = Sequence(
        muon_pre_decoding, muon_pre_decoding_prefix_sum,
        muon_sort_station_region_quarter, muon_add_coords_crossing_maps,
        muon_station_ocurrence_prefix_sum, muon_sort_by_station, is_muon)

    return muon_sequence
