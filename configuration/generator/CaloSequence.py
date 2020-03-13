from algorithms import *


def CALO_sequence(validate=False):
    populate_odin_banks = populate_odin_banks_t()
    host_global_event_cut = host_global_event_cut_t()
    calo_count_hits = calo_count_hits_t()

    prefix_sum_offsets_ecal_hits = host_prefix_sum_t(
        "prefix_sum_offsets_ecal_hits",
        host_total_sum_holder_t="host_number_of_ecal_hits_t",
        dev_input_buffer_t=calo_count_hits.dev_ecal_number_of_hits_t(),
        dev_output_buffer_t="dev_ecal_hits_offsets_t")

    prefix_sum_offsets_hcal_hits = host_prefix_sum_t(
        "prefix_sum_offsets_hcal_hits",
        host_total_sum_holder_t="host_number_of_hcal_hits_t",
        dev_input_buffer_t=calo_count_hits.dev_hcal_number_of_hits_t(),
        dev_output_buffer_t="dev_hcal_hits_offsets_t")

    calo_get_digits = calo_get_digits_t()

    calo_sequence = Sequence(
        populate_odin_banks, host_global_event_cut, calo_count_hits,
        prefix_sum_offsets_ecal_hits, prefix_sum_offsets_hcal_hits,
        calo_get_digits)
    return calo_sequence
