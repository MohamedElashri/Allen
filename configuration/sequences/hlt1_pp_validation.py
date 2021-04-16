###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from definitions.VeloSequence import VeloSequence
from definitions.PVSequence import PVSequence
from definitions.UTSequence import UTSequence
from definitions.ForwardSequence import ForwardSequence
from definitions.MuonSequence import MuonSequence
from definitions.HLT1Sequence import HLT1Sequence
from definitions.algorithms import compose_sequences, Sequence, mc_data_provider_t, \
    host_velo_validator_t, host_velo_ut_validator_t, host_forward_validator_t, \
    host_pv_validator_t, host_rate_validator_t, host_muon_validator_t, \
    host_kalman_validator_t

velo_sequence = VeloSequence()

pv_sequence = PVSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

ut_sequence = UTSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"],
    host_ut_banks=velo_sequence["host_ut_banks"])

forward_sequence = ForwardSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    velo_kalman_filter=velo_sequence["velo_kalman_filter"])

muon_sequence = MuonSequence(
    initialize_lists=velo_sequence["initialize_lists"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks_t=forward_sequence["scifi_consolidate_tracks_t"])

hlt1_sequence = HLT1Sequence(
    layout_provider=velo_sequence["mep_layout"],
    initialize_lists=velo_sequence["initialize_lists"],
    full_event_list=velo_sequence["full_event_list"],
    velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
    velo_kalman_filter=pv_sequence["velo_kalman_filter"],
    prefix_sum_offsets_velo_track_hit_number=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"],
    pv_beamline_multi_fitter=pv_sequence["pv_beamline_cleanup"],
    prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
    velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
    prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
    prefix_sum_ut_track_hit_number=ut_sequence[
        "prefix_sum_ut_track_hit_number"],
    ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
    prefix_sum_scifi_track_hit_number=forward_sequence[
        "prefix_sum_scifi_track_hit_number"],
    scifi_consolidate_tracks=forward_sequence["scifi_consolidate_tracks_t"],
    is_muon=muon_sequence["is_muon_t"])

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

host_velo_ut_validator = host_velo_ut_validator_t(
    name="host_velo_ut_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    dev_offsets_all_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].
    dev_offsets_all_velo_tracks_t(),
    dev_offsets_velo_track_hit_number_t=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
    dev_velo_track_hits_t=velo_sequence["velo_consolidate_tracks"].
    dev_velo_track_hits_t(),
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t(),
    dev_velo_kalman_endvelo_states_t=velo_sequence["velo_kalman_filter"].
    dev_velo_kalman_endvelo_states_t(),
    dev_offsets_ut_tracks_t=ut_sequence["prefix_sum_ut_tracks"].
    dev_output_buffer_t(),
    dev_offsets_ut_track_hit_number_t=ut_sequence[
        "prefix_sum_ut_track_hit_number"].dev_output_buffer_t(),
    dev_ut_track_hits_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_hits_t(),
    dev_ut_track_velo_indices_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_velo_indices_t(),
    dev_ut_qop_t=ut_sequence["ut_consolidate_tracks"].dev_ut_qop_t())

host_forward_validator = host_forward_validator_t(
    name="host_forward_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    dev_offsets_all_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].
    dev_offsets_all_velo_tracks_t(),
    dev_offsets_velo_track_hit_number_t=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
    dev_velo_track_hits_t=velo_sequence["velo_consolidate_tracks"].
    dev_velo_track_hits_t(),
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t(),
    dev_velo_kalman_endvelo_states_t=velo_sequence["velo_kalman_filter"].
    dev_velo_kalman_endvelo_states_t(),
    dev_offsets_ut_tracks_t=ut_sequence["prefix_sum_ut_tracks"].
    dev_output_buffer_t(),
    dev_offsets_ut_track_hit_number_t=ut_sequence[
        "prefix_sum_ut_track_hit_number"].dev_output_buffer_t(),
    dev_ut_track_hits_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_hits_t(),
    dev_ut_track_velo_indices_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_velo_indices_t(),
    dev_ut_qop_t=ut_sequence["ut_consolidate_tracks"].dev_ut_qop_t(),
    dev_offsets_forward_tracks_t=forward_sequence["prefix_sum_forward_tracks"].
    dev_output_buffer_t(),
    dev_offsets_scifi_track_hit_number_t=forward_sequence[
        "prefix_sum_scifi_track_hit_number"].dev_output_buffer_t(),
    dev_scifi_track_hits_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_track_hits_t(),
    dev_scifi_track_ut_indices_t=forward_sequence["scifi_consolidate_tracks_t"]
    .dev_scifi_track_ut_indices_t(),
    dev_scifi_qop_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_qop_t(),
    dev_scifi_states_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_states_t())

host_muon_validator = host_muon_validator_t(
    name="host_muon_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    dev_offsets_all_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].
    dev_offsets_all_velo_tracks_t(),
    dev_offsets_velo_track_hit_number_t=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
    dev_velo_track_hits_t=velo_sequence["velo_consolidate_tracks"].
    dev_velo_track_hits_t(),
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t(),
    dev_velo_kalman_endvelo_states_t=velo_sequence["velo_kalman_filter"].
    dev_velo_kalman_endvelo_states_t(),
    dev_offsets_ut_tracks_t=ut_sequence["prefix_sum_ut_tracks"].
    dev_output_buffer_t(),
    dev_offsets_ut_track_hit_number_t=ut_sequence[
        "prefix_sum_ut_track_hit_number"].dev_output_buffer_t(),
    dev_ut_track_hits_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_hits_t(),
    dev_ut_track_velo_indices_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_velo_indices_t(),
    dev_ut_qop_t=ut_sequence["ut_consolidate_tracks"].dev_ut_qop_t(),
    dev_offsets_forward_tracks_t=forward_sequence["prefix_sum_forward_tracks"].
    dev_output_buffer_t(),
    dev_offsets_scifi_track_hit_number_t=forward_sequence[
        "prefix_sum_scifi_track_hit_number"].dev_output_buffer_t(),
    dev_scifi_track_hits_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_track_hits_t(),
    dev_scifi_track_ut_indices_t=forward_sequence["scifi_consolidate_tracks_t"]
    .dev_scifi_track_ut_indices_t(),
    dev_scifi_qop_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_qop_t(),
    dev_scifi_states_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_states_t(),
    dev_is_muon_t=muon_sequence["is_muon_t"].dev_is_muon_t())

host_kalman_validator = host_kalman_validator_t(
    name="host_kalman_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    dev_offsets_all_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].
    dev_offsets_all_velo_tracks_t(),
    dev_offsets_velo_track_hit_number_t=velo_sequence[
        "prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
    dev_velo_track_hits_t=velo_sequence["velo_consolidate_tracks"].
    dev_velo_track_hits_t(),
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t(),
    dev_velo_kalman_states_t=velo_sequence["velo_kalman_filter"].
    dev_velo_kalman_endvelo_states_t(),
    dev_offsets_ut_tracks_t=ut_sequence["prefix_sum_ut_tracks"].
    dev_output_buffer_t(),
    dev_offsets_ut_track_hit_number_t=ut_sequence[
        "prefix_sum_ut_track_hit_number"].dev_output_buffer_t(),
    dev_ut_track_hits_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_hits_t(),
    dev_ut_track_velo_indices_t=ut_sequence["ut_consolidate_tracks"].
    dev_ut_track_velo_indices_t(),
    dev_ut_qop_t=ut_sequence["ut_consolidate_tracks"].dev_ut_qop_t(),
    dev_offsets_forward_tracks_t=forward_sequence["prefix_sum_forward_tracks"].
    dev_output_buffer_t(),
    dev_offsets_scifi_track_hit_number_t=forward_sequence[
        "prefix_sum_scifi_track_hit_number"].dev_output_buffer_t(),
    dev_scifi_track_hits_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_track_hits_t(),
    dev_scifi_track_ut_indices_t=forward_sequence["scifi_consolidate_tracks_t"]
    .dev_scifi_track_ut_indices_t(),
    dev_scifi_qop_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_qop_t(),
    dev_scifi_states_t=forward_sequence["scifi_consolidate_tracks_t"].
    dev_scifi_states_t(),
    dev_kf_tracks_t=hlt1_sequence["kalman_velo_only"].dev_kf_tracks_t(),
    dev_multi_final_vertices_t=pv_sequence["pv_beamline_cleanup"].
    dev_multi_final_vertices_t(),
    dev_number_of_multi_final_vertices_t=pv_sequence["pv_beamline_cleanup"].
    dev_number_of_multi_final_vertices_t())

host_pv_validator = host_pv_validator_t(
    name="host_pv_validator",
    dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
    host_mc_events_t=mc_data_provider.host_mc_events_t(),
    dev_multi_final_vertices_t=pv_sequence["pv_beamline_cleanup"].
    dev_multi_final_vertices_t(),
    dev_number_of_multi_final_vertices_t=pv_sequence["pv_beamline_cleanup"].
    dev_number_of_multi_final_vertices_t())

host_rate_validator = host_rate_validator_t(
    name="host_rate_validator",
    host_number_of_events_t=velo_sequence["initialize_lists"].
    host_number_of_events_t(),
    host_names_of_lines_t=hlt1_sequence["gather_selections"].
    host_names_of_active_lines_t(),
    host_number_of_active_lines_t=hlt1_sequence["gather_selections"].
    host_number_of_active_lines_t(),
    dev_selections_t=hlt1_sequence["gather_selections"].dev_selections_t(),
    dev_selections_offsets_t=hlt1_sequence["gather_selections"].
    dev_selections_offsets_t())

validation_sequence = Sequence(mc_data_provider, host_velo_validator,
                               host_velo_ut_validator, host_forward_validator,
                               host_muon_validator, host_pv_validator,
                               host_rate_validator, host_kalman_validator)

my_sequence = compose_sequences(velo_sequence, pv_sequence, ut_sequence,
                                forward_sequence, muon_sequence, hlt1_sequence,
                                validation_sequence)

print(my_sequence)
my_sequence.generate()
