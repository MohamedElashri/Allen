###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from AllenCore.algorithms import data_provider_t, plume_decode_t, host_prefix_sum_t
from AllenConf.utils import initialize_number_of_events
from AllenCore.generator import make_algorithm


def decode_plume():
    number_of_events = initialize_number_of_events()
    Plume_banks = make_algorithm(
        data_provider_t, name="Plume_banks", bank_type="Plume")

    #plume_count_digits = make_algorithm(
    #    calo_count_digits_t,
    #    name="plume_count_digits",
    #    host_number_of_events_t=number_of_events["host_number_of_events"],
    #    dev_number_of_events_t=number_of_events["dev_number_of_events"])

    # prefix_sum_plume_num_digits = make_algorithm(
    #    host_prefix_sum_t,
    #    name="prefix_sum_plume_num_digits",
    #    dev_input_buffer_t=plume_count_digits.dev_ecal_num_digits_t)

    plume_decode = make_algorithm(
        plume_decode_t,
        name="plume_decode",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_raw_bank_version_t=Plume_banks.host_raw_bank_version_t,
        #	host_plume_number_of_llt_t=prefix_sum_plume_num_digits.host_total_sum_holder_t,
        dev_plume_raw_input_t=Plume_banks.dev_raw_banks_t,
        dev_plume_raw_input_offsets_t=Plume_banks.dev_raw_offsets_t,
        dev_plume_raw_input_sizes_t=Plume_banks.dev_raw_sizes_t,
        dev_plume_raw_input_types_t=Plume_banks.dev_raw_types_t)
    #	dev_plume_offsets_t=prefix_sum_plume_num_digits.dev_output_buffer_t)

    return {
        "plume_algo": plume_decode,
        "dev_plume": plume_decode.dev_plume_t,
    }


'dev_plume_raw_input_t', 'dev_plume_raw_input_types_t', 'dev_plume_raw_input_sizes_t'
