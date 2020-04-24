from algorithms import *


def CALO_sequence(validate=False):
    populate_odin_banks = populate_odin_banks_t()
    host_global_event_cut = host_global_event_cut_t()

    calo_get_digits = calo_get_digits_t()

    calo_find_clusters = calo_find_clusters_t()

    calo_sequence = Sequence(
        populate_odin_banks, host_global_event_cut,
        calo_get_digits, calo_find_clusters)
    return calo_sequence
