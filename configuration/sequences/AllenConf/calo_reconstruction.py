###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from AllenConf.algorithms import data_provider_t, calo_count_digits_t, host_prefix_sum_t, calo_decode_t
from AllenConf.utils import initialize_number_of_events
from AllenCore.event_list_utils import make_algorithm


def decode_calo():
    number_of_events = initialize_number_of_events()
    ecal_banks = make_algorithm(
        data_provider_t, name="ecal_banks", bank_type="EcalPacked")
    hcal_banks = make_algorithm(
        data_provider_t, name="hcal_banks", bank_type="HcalPacked")

    calo_count_digits = make_algorithm(
        calo_count_digits_t,
        name="calo_count_digits",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        dev_number_of_events_t=number_of_events["dev_number_of_events"])

    prefix_sum_ecal_num_digits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_ecal_num_digits",
        dev_input_buffer_t=calo_count_digits.dev_ecal_num_digits_t)

    prefix_sum_hcal_num_digits = make_algorithm(
        host_prefix_sum_t,
        name="prefix_sum_hcal_num_digits",
        dev_input_buffer_t=calo_count_digits.dev_hcal_num_digits_t)

    calo_decode = make_algorithm(
        calo_decode_t,
        name="calo_decode",
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_ecal_number_of_digits_t=prefix_sum_ecal_num_digits.
        host_total_sum_holder_t,
        host_hcal_number_of_digits_t=prefix_sum_hcal_num_digits.
        host_total_sum_holder_t,
        dev_ecal_raw_input_t=ecal_banks.dev_raw_banks_t,
        dev_ecal_raw_input_offsets_t=ecal_banks.dev_raw_offsets_t,
        dev_hcal_raw_input_t=hcal_banks.dev_raw_banks_t,
        dev_hcal_raw_input_offsets_t=hcal_banks.dev_raw_offsets_t,
        dev_ecal_digits_offsets_t=prefix_sum_ecal_num_digits.
        dev_output_buffer_t,
        dev_hcal_digits_offsets_t=prefix_sum_hcal_num_digits.
        dev_output_buffer_t)

    return {
        "dev_ecal_digits": calo_decode.dev_ecal_digits_t,
        "dev_hcal_digits": calo_decode.dev_hcal_digits_t
    }
