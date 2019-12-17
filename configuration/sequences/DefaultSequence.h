
/**
 * Specify here all arguments with their association to algorithm arguments.
 */
ARG(host_event_list_t, host_global_event_cut::host_event_list_t)
ARG(host_number_of_selected_events_t,
  host_global_event_cut::host_number_of_selected_events_t,
  velo_estimate_input_size::host_number_of_selected_events_t,
  velo_consolidate_tracks::host_number_of_selected_events_t)
ARG(
  dev_event_list_t,
  host_global_event_cut::dev_event_list_t,
  velo_estimate_input_size::dev_event_list_t,
  velo_masked_clustering::dev_event_list_t)
ARG(
  dev_estimated_input_size_t,
  velo_estimate_input_size::dev_estimated_input_size_t,
  _cpu_prefix_sum::dev_buffer_t,
  velo_masked_clustering::dev_estimated_input_size_t,
  velo_calculate_phi_and_sort::dev_estimated_input_size_t,
  velo_fill_candidates::dev_estimated_input_size_t,
  velo_search_by_triplet::dev_estimated_input_size_t,
  velo_weak_tracks_adder::dev_estimated_input_size_t,
  velo_consolidate_tracks::dev_estimated_input_size_t)
ARG(dev_velo_raw_input_t, velo_estimate_input_size::dev_velo_raw_input_t, velo_masked_clustering::dev_velo_raw_input_t)
ARG(
  dev_velo_raw_input_offsets_t,
  velo_estimate_input_size::dev_velo_raw_input_offsets_t,
  velo_masked_clustering::dev_velo_raw_input_offsets_t)
ARG(
  dev_module_candidate_num_t,
  velo_estimate_input_size::dev_module_candidate_num_t,
  velo_masked_clustering::dev_module_candidate_num_t)
ARG(
  dev_cluster_candidates_t,
  velo_estimate_input_size::dev_cluster_candidates_t,
  velo_masked_clustering::dev_cluster_candidates_t)
ARG(
  dev_module_cluster_num_t,
  velo_masked_clustering::dev_module_cluster_num_t,
  velo_calculate_phi_and_sort::dev_module_cluster_num_t,
  velo_fill_candidates::dev_module_cluster_num_t,
  velo_search_by_triplet::dev_module_cluster_num_t)
ARG(
  dev_velo_cluster_container_t,
  velo_masked_clustering::dev_velo_cluster_container_t,
  velo_calculate_phi_and_sort::dev_velo_cluster_container_t,
  velo_fill_candidates::dev_velo_cluster_container_t,
  velo_search_by_triplet::dev_velo_cluster_container_t,
  velo_weak_tracks_adder::dev_velo_cluster_container_t,
  velo_consolidate_tracks::dev_velo_cluster_container_t)
ARG(dev_hit_permutation_t, velo_calculate_phi_and_sort::dev_hit_permutation_t)
ARG(dev_h0_candidates_t, velo_fill_candidates::dev_h0_candidates_t, velo_search_by_triplet::dev_h0_candidates_t)
ARG(dev_h2_candidates_t, velo_fill_candidates::dev_h2_candidates_t, velo_search_by_triplet::dev_h2_candidates_t)
ARG(
  dev_tracks_t,
  velo_search_by_triplet::dev_tracks_t,
  velo_weak_tracks_adder::dev_tracks_t,
  velo_copy_track_hit_number::dev_tracks_t,
  velo_consolidate_tracks::dev_tracks_t)
ARG(dev_tracklets_t, velo_search_by_triplet::dev_tracklets_t)
ARG(dev_tracks_to_follow_t, velo_search_by_triplet::dev_tracks_to_follow_t)
ARG(dev_weak_tracks_t, velo_search_by_triplet::dev_weak_tracks_t, velo_weak_tracks_adder::dev_weak_tracks_t)
ARG(dev_hit_used_t, velo_search_by_triplet::dev_hit_used_t, velo_weak_tracks_adder::dev_hit_used_t)
ARG(
  dev_atomics_velo_t,
  velo_search_by_triplet::dev_atomics_velo_t,
  velo_weak_tracks_adder::dev_atomics_velo_t,
  cpu_velo_prefix_sum_number_of_tracks::dev_atomics_velo_t,
  velo_copy_track_hit_number::dev_atomics_velo_t,
  velo_consolidate_tracks::dev_atomics_velo_t,
  _cpu_prefix_sum::dev_buffer_t)
ARG(dev_rel_indices_t, velo_search_by_triplet::dev_rel_indices_t)
ARG(
  dev_velo_track_hit_number_t,
  velo_copy_track_hit_number::dev_velo_track_hit_number_t,
  cpu_velo_prefix_sum_number_of_track_hits::dev_velo_track_hit_number_t,
  velo_consolidate_tracks::dev_velo_track_hit_number_t,
  _cpu_prefix_sum::dev_buffer_t)
ARG(dev_velo_track_hits_t, velo_consolidate_tracks::dev_velo_track_hits_t)
ARG(dev_velo_states_t, velo_consolidate_tracks::dev_velo_states_t)
ARG(dev_accepted_velo_tracks_t, velo_consolidate_tracks::dev_accepted_velo_tracks_t)

ARG(
  host_total_number_of_velo_clusters_t,
  _cpu_prefix_sum::host_total_sum_holder_t,
  velo_masked_clustering::host_total_number_of_velo_clusters_t,
  velo_calculate_phi_and_sort::host_total_number_of_velo_clusters_t,
  velo_fill_candidates::host_total_number_of_velo_clusters_t,
  velo_search_by_triplet::host_total_number_of_velo_clusters_t)

ARG(
  host_number_of_reconstructed_velo_tracks_t,
  _cpu_prefix_sum::host_total_sum_holder_t,
  velo_copy_track_hit_number::host_number_of_reconstructed_velo_tracks_t,
  velo_consolidate_tracks::host_number_of_reconstructed_velo_tracks_t)

ARG(host_accumulated_number_of_hits_in_velo_tracks_t,
  _cpu_prefix_sum::host_total_sum_holder_t,
  velo_consolidate_tracks::host_accumulated_number_of_hits_in_velo_tracks_t)

/**
 * Specify here the algorithms to be executed in the sequence,
 * in the expected order of execution, with their arguments.
 */
SEQUENCE_T(
  host_global_event_cut::host_global_event_cut_t<
    std::tuple<dev_event_list_t, host_event_list_t, host_number_of_selected_events_t>>,
  velo_estimate_input_size::velo_estimate_input_size_t<std::tuple<
    host_number_of_selected_events_t,
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    dev_estimated_input_size_t,
    dev_module_candidate_num_t,
    dev_cluster_candidates_t,
    dev_event_list_t>>,
  _cpu_prefix_sum::cpu_prefix_sum_t<std::tuple<host_total_number_of_velo_clusters_t, dev_estimated_input_size_t>>,
  velo_masked_clustering::velo_masked_clustering_t<std::tuple<
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    dev_estimated_input_size_t,
    dev_module_candidate_num_t,
    dev_cluster_candidates_t,
    dev_event_list_t,
    dev_module_cluster_num_t,
    dev_velo_cluster_container_t,
    host_total_number_of_velo_clusters_t>>,
  velo_calculate_phi_and_sort::velo_calculate_phi_and_sort_t<std::tuple<
    dev_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_velo_cluster_container_t,
    dev_hit_permutation_t,
    host_total_number_of_velo_clusters_t>>,
  velo_fill_candidates::velo_fill_candidates_t<std::tuple<
    dev_velo_cluster_container_t,
    dev_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_h0_candidates_t,
    dev_h2_candidates_t,
    host_total_number_of_velo_clusters_t>>,
  velo_search_by_triplet::velo_search_by_triplet_t<std::tuple<
    dev_velo_cluster_container_t,
    dev_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_tracks_t,
    dev_tracklets_t,
    dev_tracks_to_follow_t,
    dev_weak_tracks_t,
    dev_hit_used_t,
    dev_atomics_velo_t,
    dev_h0_candidates_t,
    dev_h2_candidates_t,
    dev_rel_indices_t,
    host_total_number_of_velo_clusters_t>>,
  velo_weak_tracks_adder::velo_weak_tracks_adder_t<std::tuple<
    dev_velo_cluster_container_t,
    dev_estimated_input_size_t,
    dev_tracks_t,
    dev_weak_tracks_t,
    dev_hit_used_t,
    dev_atomics_velo_t>>,
  _cpu_prefix_sum::cpu_prefix_sum_t<std::tuple<host_number_of_reconstructed_velo_tracks_t, dev_atomics_velo_t>>,
  velo_copy_track_hit_number::velo_copy_track_hit_number_t<
    std::tuple<host_number_of_reconstructed_velo_tracks_t, dev_tracks_t, dev_atomics_velo_t, dev_velo_track_hit_number_t>>,
  _cpu_prefix_sum::cpu_prefix_sum_t<std::tuple<host_accumulated_number_of_hits_in_velo_tracks_t, dev_velo_track_hit_number_t>>,
  velo_consolidate_tracks::velo_consolidate_tracks_t<std::tuple<
    host_accumulated_number_of_hits_in_velo_tracks_t,
    host_number_of_reconstructed_velo_tracks_t,
    host_number_of_selected_events_t,
    dev_atomics_velo_t,
    dev_tracks_t,
    dev_velo_track_hit_number_t,
    dev_velo_cluster_container_t,
    dev_estimated_input_size_t,
    dev_velo_track_hits_t,
    dev_velo_states_t,
    dev_accepted_velo_tracks_t>>
  // velo_kalman_fit_t,
  // pv_beamline_extrapolate_t,
  // pv_beamline_histo_t,
  // pv_beamline_peak_t,
  // pv_beamline_calculate_denom_t,
  // pv_beamline_multi_fitter_t,
  // pv_beamline_cleanup_t,
  // ut_calculate_number_of_hits_t,
  // cpu_ut_prefix_sum_number_of_hits_t,
  // ut_pre_decode_t,
  // ut_find_permutation_t,
  // ut_decode_raw_banks_in_order_t,
  // ut_search_windows_t,
  // compass_ut_t,
  // cpu_ut_prefix_sum_number_of_tracks_t,
  // ut_copy_track_hit_number_t,
  // cpu_ut_prefix_sum_number_of_track_hits_t,
  // ut_consolidate_tracks_t,
  // scifi_calculate_cluster_count_v4_t,
  // cpu_scifi_prefix_sum_number_of_hits_t,
  // scifi_pre_decode_v4_t,
  // scifi_raw_bank_decoder_v4_t,
  // scifi_direct_decoder_v4_t,
  // lf_search_initial_windows_t,
  // lf_triplet_seeding_t,
  // lf_triplet_keep_best_t,
  // lf_calculate_parametrization_t,
  // lf_extend_tracks_x_t,
  // lf_extend_tracks_uv_t,
  // lf_quality_filter_length_t,
  // lf_quality_filter_t,
  // cpu_scifi_prefix_sum_number_of_tracks_t,
  // scifi_copy_track_hit_number_t,
  // cpu_scifi_prefix_sum_number_of_track_hits_t,
  // scifi_consolidate_tracks_t,
  // muon_pre_decoding_t,
  // cpu_muon_prefix_sum_storage_t,
  // muon_sort_station_region_quarter_t,
  // muon_add_coords_crossing_maps_t,
  // cpu_muon_prefix_sum_station_t,
  // muon_sort_by_station_t,
  // is_muon_t,
  // kalman_velo_only_t,
  // kalman_pv_ipchi2_t,
  // cpu_sv_prefix_sum_offsets_t,
  // fit_secondary_vertices_t,
  // run_hlt1_t,
  // prepare_raw_banks_t
)