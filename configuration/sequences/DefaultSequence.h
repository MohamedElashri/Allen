/**
 * Specify here the algorithms to be executed in the sequence,
 * in the expected order of execution.
 */
struct dev_velo_raw_input_t : velo_estimate_input_size::velo_raw_input_t
{
  constexpr static auto name {"dev_velo_raw_input_t"};
  size_t size;
  char* offset;
};

struct dev_velo_raw_input_offsets_t : velo_estimate_input_size::velo_raw_input_offsets_t {
  constexpr static auto name {"dev_velo_raw_input_offsets_t"};
  size_t size;
  char* offset;
};

struct dev_estimated_input_size_t : velo_estimate_input_size::estimated_input_size_t {
  constexpr static auto name {"dev_estimated_input_size_t"};
  size_t size;
  char* offset;
};

struct dev_module_candidate_num_t : velo_estimate_input_size::module_candidate_num_t {
  constexpr static auto name {"dev_module_candidate_num_t"};
  size_t size;
  char* offset;
};

struct dev_cluster_candidates_t : velo_estimate_input_size::cluster_candidates_t {
  constexpr static auto name {"dev_cluster_candidates_t"};
  size_t size;
  char* offset;
};

struct dev_event_list_t : velo_estimate_input_size::event_list_t {
  constexpr static auto name {"dev_event_list_t"};
  size_t size;
  char* offset;
};

SEQUENCE_T(
  // cpu_init_event_list_t,
  // cpu_global_event_cut_t,
  velo_estimate_input_size::velo_estimate_input_size_t<std::tuple<
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    dev_estimated_input_size_t,
    dev_module_candidate_num_t,
    dev_cluster_candidates_t,
    dev_event_list_t>>
  // cpu_velo_prefix_sum_number_of_clusters_t,
  // velo_masked_clustering_t,
  // velo_calculate_phi_and_sort_t,
  // velo_fill_candidates_t,
  // velo_search_by_triplet_t<dev_velo_raw_input_t>,
  // velo_weak_tracks_adder_t,
  // cpu_velo_prefix_sum_number_of_tracks_t,
  // velo_copy_track_hit_number_t,
  // cpu_velo_prefix_sum_number_of_track_hits_t,
  // velo_consolidate_tracks_t,
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