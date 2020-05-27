from definitions.algorithms import *


def CaloSequence(initialize_lists):
    ecal_banks = data_provider_t(name="ecal_banks", bank_type="ECal")
    hcal_banks = data_provider_t(name="hcal_banks", bank_type="HCal")

    calo_decode = calo_decode_t(
        name="calo_decode",
        host_number_of_selected_events_t=initialize_lists.
        host_number_of_selected_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_ecal_raw_input_t=ecal_banks.dev_raw_banks_t(),
        dev_ecal_raw_input_offsets_t=ecal_banks.dev_raw_offsets_t(),
        dev_hcal_raw_input_t=hcal_banks.dev_raw_banks_t(),
        dev_hcal_raw_input_offsets_t=hcal_banks.dev_raw_offsets_t())

    # calo_find_local_maxima = calo_find_local_maxima_t()

    # prefix_sum_ecal_num_clusters = host_prefix_sum_t(
    #     "prefix_sum_ecal_num_clusters",
    #     host_total_sum_holder_t="host_ecal_number_of_clusters_t",
    #     dev_input_buffer_t=calo_find_local_maxima.dev_ecal_num_clusters_t(),
    #     dev_output_buffer_t="dev_ecal_cluster_offsets_t")

    # prefix_sum_hcal_num_clusters = host_prefix_sum_t(
    #     "prefix_sum_hcal_num_clusters",
    #     host_total_sum_holder_t="host_hcal_number_of_clusters_t",
    #     dev_input_buffer_t=calo_find_local_maxima.dev_hcal_num_clusters_t(),
    #     dev_output_buffer_t="dev_hcal_cluster_offsets_t")

    # calo_set_cluster_centers = calo_set_cluster_centers_t()

    # calo_find_clusters = calo_find_clusters_t()

    # calo_sequence = Sequence(
    #     populate_odin_banks, host_global_event_cut,
    #     calo_get_digits, calo_find_local_maxima,
    #     prefix_sum_ecal_num_clusters, prefix_sum_hcal_num_clusters,
    #     calo_set_cluster_centers, calo_find_clusters)

    calo_sequence = Sequence(
        ecal_banks, hcal_banks, calo_decode)

    return calo_sequence
