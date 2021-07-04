###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from AllenCore.generator import make_algorithm
from AllenConf.algorithms import (host_init_number_of_events_t,
                                  host_data_provider_t,
                                  host_global_event_cut_t, layout_provider_t)


def initialize_number_of_events():
    initialize_number_of_events = make_algorithm(
        host_init_number_of_events_t, name="initialize_number_of_events")
    return {
        "host_number_of_events":
        initialize_number_of_events.host_number_of_events_t,
        "dev_number_of_events":
        initialize_number_of_events.dev_number_of_events_t,
    }


def gec(name="gec", min_scifi_ut_clusters="0", max_scifi_ut_clusters="9750"):
    number_of_events = initialize_number_of_events()

    host_ut_banks = make_algorithm(
        host_data_provider_t, name="host_ut_banks", bank_type="UT")

    host_scifi_banks = make_algorithm(
        host_data_provider_t, name="host_scifi_banks", bank_type="FTCluster")

    gec = make_algorithm(
        host_global_event_cut_t,
        name=name,
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters,
        host_ut_raw_bank_version_t=host_ut_banks.host_raw_bank_version_t)

    return gec


def mep_layout():
    layout = make_algorithm(layout_provider_t, name="mep_layout")
    return {
        "host_mep_layout": layout.host_mep_layout_t,
        "dev_mep_layout": layout.dev_mep_layout_t
    }
