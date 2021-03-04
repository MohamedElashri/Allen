###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import VeloSequence
from definitions.algorithms import compose_sequences, Sequence, mc_data_provider_t, \
    host_velo_validator_t
    
velo_sequence = VeloSequence()

mc_data_provider = mc_data_provider_t(name="mc_data_provider")

host_velo_validator = host_velo_validator_t(
    name="host_velo_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    dev_offsets_all_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].
    dev_offsets_all_velo_tracks_t(),
    dev_offsets_velo_track_hit_number_t=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
    dev_velo_track_hits_t=velo_sequence["velo_consolidate_tracks"].
    dev_velo_track_hits_t(),
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t())

compose_sequences(velo_sequence, Sequence(mc_data_provider, host_velo_validator)).generate()
