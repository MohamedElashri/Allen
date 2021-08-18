from definitions.algorithms import *
from .HLT1Sequence import make_selection_gatherer

def PassthroughSequence():

    mep_layout = layout_provider_t(name="mep_layout")

    initialize_lists = host_init_event_list_t(
        name="initialize_lists")
    
    odin_banks = data_provider_t(name="odin_banks", bank_type="ODIN")
    velo_banks = data_provider_t(name="velo_banks", bank_type="VP")

    # velo_calculate_number_of_candidates = velo_calculate_number_of_candidates_t(
    #     name="velo_calculate_number_of_candidates",
    #     host_number_of_events_t=initialize_lists.host_number_of_events_t(),
    #     dev_event_list_t=initialize_lists.dev_event_list_t(),
    #     dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
    #     dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t())

    # prefix_sum_offsets_velo_candidates = host_prefix_sum_t(
    #     name="prefix_sum_offsets_velo_candidates",
    #     dev_input_buffer_t=velo_calculate_number_of_candidates.
    #     dev_number_of_candidates_t())

    # velo_estimate_input_size = velo_estimate_input_size_t(
    #     name="velo_estimate_input_size",
    #     host_number_of_events_t=initialize_lists.host_number_of_events_t(),
    #     host_number_of_cluster_candidates_t=prefix_sum_offsets_velo_candidates.
    #     host_total_sum_holder_t(),
    #     dev_event_list_t=initialize_lists.dev_event_list_t(),
    #     dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
    #     dev_output_buffer_t(),
    #     dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
    #     dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t())

    # prefix_sum_offsets_estimated_input_size = host_prefix_sum_t(
    #     name="prefix_sum_offsets_estimated_input_size",
    #     dev_input_buffer_t=velo_estimate_input_size.
    #     dev_estimated_input_size_t())

    # velo_masked_clustering = velo_masked_clustering_t(
    #     name="velo_masked_clustering",
    #     host_total_number_of_velo_clusters_t=
    #     prefix_sum_offsets_estimated_input_size.host_total_sum_holder_t(),
    #     host_number_of_events_t=initialize_lists.host_number_of_events_t(),
    #     dev_velo_raw_input_t=velo_banks.dev_raw_banks_t(),
    #     dev_velo_raw_input_offsets_t=velo_banks.dev_raw_offsets_t(),
    #     dev_offsets_estimated_input_size_t=
    #     prefix_sum_offsets_estimated_input_size.dev_output_buffer_t(),
    #     dev_module_candidate_num_t=velo_estimate_input_size.
    #     dev_module_candidate_num_t(),
    #     dev_cluster_candidates_t=velo_estimate_input_size.
    #     dev_cluster_candidates_t(),
    #     dev_event_list_t=initialize_lists.dev_event_list_t(),
    #     dev_candidates_offsets_t=prefix_sum_offsets_velo_candidates.
    #     dev_output_buffer_t(),
    #     dev_number_of_events_t=initialize_lists.dev_number_of_events_t())

    ut_banks = data_provider_t(name="ut_banks", bank_type="UT")
    scifi_banks = data_provider_t(name="scifi_banks", bank_type="FTCluster")
    muon_banks = data_provider_t(name="muon_banks", bank_type="Muon")

    passthrough_line = passthrough_line_t(
        name="Hlt1Passthrough",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_event_list_t=initialize_lists.dev_event_list_t(),
        dev_odin_raw_input_t=odin_banks.dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=odin_banks.dev_raw_offsets_t(),
        dev_mep_layout_t=mep_layout.dev_mep_layout_t(),
        pre_scaler_hash_string="passthrough_line_pre",
        post_scaler_hash_string="passthrough_line_post")

    lines = (passthrough_line,)
    gatherer = make_selection_gatherer(
        lines,
        initialize_lists,
        mep_layout,
        odin_banks,
        name="gather_selections")

    dec_reporter = dec_reporter_t(
        name="dec_reporter",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_active_lines_t=gatherer.
        host_number_of_active_lines_t(),
        dev_number_of_active_lines_t=gatherer.
        dev_number_of_active_lines_t(),
        dev_selections_t=gatherer.dev_selections_t(),
        dev_selections_offsets_t=gatherer.dev_selections_offsets_t())

    global_decision = global_decision_t(
        name="global_decision",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_active_lines_t=gatherer.
        host_number_of_active_lines_t(),
        dev_number_of_events_t=initialize_lists.dev_number_of_events_t(),
        dev_number_of_active_lines_t=gatherer.
        dev_number_of_active_lines_t(),
        dev_dec_reports_t=dec_reporter.dev_dec_reports_t())

    rate_reporter = host_rate_validator_t(
        name="rate_reporter",
        host_number_of_events_t=initialize_lists.host_number_of_events_t(),
        host_number_of_active_lines_t=gatherer.
        host_number_of_active_lines_t(),
        host_names_of_lines_t=gatherer.host_names_of_active_lines_t(),
        host_dec_reports_t=dec_reporter.host_dec_reports_t())

    return Sequence(mep_layout, initialize_lists,
                    velo_banks,
                    # velo_calculate_number_of_candidates,
                    # prefix_sum_offsets_velo_candidates,
                    # velo_estimate_input_size,
                    # prefix_sum_offsets_estimated_input_size,
                    # velo_masked_clustering,
                    ut_banks, scifi_banks, muon_banks, odin_banks,
                    *lines, gatherer,
                    dec_reporter, global_decision)
