from algorithms import *


def CALO_sequence(validate=False):
    populate_odin_banks = populate_odin_banks_t()
    host_global_event_cut = host_global_event_cut_t()
    calo_count_hits = calo_count_hits_t()

    calo_sequence = Sequence(
        populate_odin_banks, host_global_event_cut, calo_count_hits)
    return calo_sequence
