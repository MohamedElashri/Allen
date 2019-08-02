/**
 * Specify here the algorithms to be executed in the sequence,
 * in the expected order of execution.
 */
SEQUENCE_T(
  init_event_list_t,
  global_event_cut_t,

  // Velo data preparation
  velo_estimate_input_size_t,
  prefix_sum_velo_clusters_t,
  velo_masked_clustering_t,

  // UT data preparation
  ut_calculate_number_of_hits_t,
  prefix_sum_ut_hits_t,
  ut_pre_decode_t,
  ut_find_permutation_t,
  ut_decode_raw_banks_in_order_t,

  // SciFi data preparation
  scifi_calculate_cluster_count_v6_t,
  prefix_sum_scifi_hits_t,
  scifi_pre_decode_v6_t,
  scifi_raw_bank_decoder_v6_t,

  // Muon data preparation
  muon_pre_decoding_t,
  muon_pre_decoding_prefix_sum_t,
  muon_sort_station_region_quarter_t,
  muon_add_coords_crossing_maps_t,
  muon_station_ocurrence_prefix_sum_t,
  muon_sort_by_station_t, )
