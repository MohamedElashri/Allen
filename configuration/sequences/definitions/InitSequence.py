from minipyconf.control_flow import Leaf
from definitions.event_list_utils import make_algorithm
from definitions.algorithms import *


def initialize_number_of_events(**kwargs):
    initialize_number_of_events = make_algorithm(host_init_number_of_events_t, name="initialize_number_of_events")
    return {
        "host_number_of_events": initialize_number_of_events.host_number_of_events_t,
        "dev_number_of_events": initialize_number_of_events.dev_number_of_events_t,
    }


def gec(min_scifi_ut_clusters="0", max_scifi_ut_clusters="9750", **kwargs):
    number_of_events = initialize_number_of_events(**kwargs)

    host_ut_banks = make_algorithm(
        host_data_provider_t, name="host_ut_banks", bank_type="UT"
    )

    host_scifi_banks = make_algorithm(
        host_data_provider_t, name="host_scifi_banks", bank_type="FTCluster"
    )

    gec = make_algorithm(
        host_global_event_cut_t,
        name="global_event_cut",
        host_ut_raw_banks_t=host_ut_banks.host_raw_banks_t,
        host_ut_raw_offsets_t=host_ut_banks.host_raw_offsets_t,
        host_scifi_raw_banks_t=host_scifi_banks.host_raw_banks_t,
        host_scifi_raw_offsets_t=host_scifi_banks.host_raw_offsets_t,
        min_scifi_ut_clusters=min_scifi_ut_clusters,
        max_scifi_ut_clusters=max_scifi_ut_clusters,
    )

    return gec
