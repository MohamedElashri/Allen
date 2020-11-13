from definitions.algorithms import *


def GECSequence(doGEC=True):
    mep_layout = layout_provider_t(name="mep_layout")

    host_ut_banks = host_data_provider_t(name="host_ut_banks", bank_type="UT")

    host_scifi_banks = host_data_provider_t(
        name="host_scifi_banks", bank_type="FTCluster")

    initialize_lists = None
    if doGEC:
        initialize_lists = host_global_event_cut_t(
            name="initialize_lists",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())
    else:
        initialize_lists = host_init_event_list_t(
            name="initialize_lists",
            host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
            host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
            host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
            host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())

    full_event_list = host_init_event_list_t(
        name="full_event_list",
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t(),
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t(),
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t(),
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t())

        
    gec_sequence = Sequence(
        mep_layout, host_ut_banks, host_scifi_banks, initialize_lists, full_event_list)

    return gec_sequence
