###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.algorithms import *


def CaloSequence(initialize_lists):
    ecal_banks = data_provider_t(name="ecal_banks", bank_type="EcalPacked")
    hcal_banks = data_provider_t(name="hcal_banks", bank_type="HcalPacked")

    calo_count_digits = calo_count_digits_t(
        name="calo_count_digits",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t())

    prefix_sum_ecal_num_digits = host_prefix_sum_t(
        name="prefix_sum_ecal_num_digits",
        dev_input_buffer_t=calo_count_digits.dev_ecal_num_digits_t())

    prefix_sum_hcal_num_digits = host_prefix_sum_t(
        name="prefix_sum_hcal_num_digits",
        dev_input_buffer_t=calo_count_digits.dev_hcal_num_digits_t())

    calo_decode = calo_decode_t(
        name="calo_decode",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_ecal_number_of_digits_t=prefix_sum_ecal_num_digits.
        host_total_sum_holder_t(),
        host_hcal_number_of_digits_t=prefix_sum_hcal_num_digits.
        host_total_sum_holder_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_ecal_raw_input_t=ecal_banks.dev_raw_banks_t(),
        dev_ecal_raw_input_offsets_t=ecal_banks.dev_raw_offsets_t(),
        dev_hcal_raw_input_t=hcal_banks.dev_raw_banks_t(),
        dev_hcal_raw_input_offsets_t=hcal_banks.dev_raw_offsets_t(),
        dev_ecal_digits_offsets_t=prefix_sum_ecal_num_digits.
        dev_output_buffer_t(),
        dev_hcal_digits_offsets_t=prefix_sum_hcal_num_digits.
        dev_output_buffer_t())

    calo_sequence = Sequence(ecal_banks, hcal_banks, calo_count_digits,
                             prefix_sum_ecal_num_digits,
                             prefix_sum_hcal_num_digits, calo_decode)

    return calo_sequence
