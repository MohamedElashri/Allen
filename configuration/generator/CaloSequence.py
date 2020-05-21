from algorithms import *


def CALO_sequence(validate=False):
    populate_odin_banks = populate_odin_banks_t()
    host_global_event_cut = host_global_event_cut_t()

    calo_get_digits = calo_get_digits_t()

    calo_find_local_maxima = calo_find_local_maxima_t()

    prefix_sum_ecal_num_clusters = host_prefix_sum_t(
        "prefix_sum_ecal_num_clusters",
        host_total_sum_holder_t="host_ecal_number_of_clusters_t",
        dev_input_buffer_t=calo_find_local_maxima.dev_ecal_num_clusters_t(),
        dev_output_buffer_t="dev_ecal_cluster_offsets_t")

    prefix_sum_hcal_num_clusters = host_prefix_sum_t(
        "prefix_sum_hcal_num_clusters",
        host_total_sum_holder_t="host_hcal_number_of_clusters_t",
        dev_input_buffer_t=calo_find_local_maxima.dev_hcal_num_clusters_t(),
        dev_output_buffer_t="dev_hcal_cluster_offsets_t")

    calo_set_cluster_centers = calo_set_cluster_centers_t()

    calo_find_clusters = calo_find_clusters_t()

    calo_sequence = Sequence(
        populate_odin_banks, host_global_event_cut,
        calo_get_digits, calo_find_local_maxima,
        prefix_sum_ecal_num_clusters, prefix_sum_hcal_num_clusters,
        calo_set_cluster_centers, calo_find_clusters)
    return calo_sequence
