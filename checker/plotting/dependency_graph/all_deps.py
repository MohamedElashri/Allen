all_dependencies = [
    ['cpu_init_event_list_t', ['dev_event_list']],
    ['cpu_global_event_cut_t', ['dev_event_list']],
    [
        'velo_estimate_input_size_t',
        [
            'dev_velo_raw_input', 'dev_velo_raw_input_offsets',
            'dev_estimated_input_size', 'dev_module_cluster_num',
            'dev_module_candidate_num', 'dev_cluster_candidates',
            'dev_event_list'
        ]
    ],
    ['cpu_velo_prefix_sum_number_of_clusters_t', ['dev_estimated_input_size']],
    [
        'velo_masked_clustering_t',
        [
            'dev_velo_raw_input', 'dev_velo_raw_input_offsets',
            'dev_estimated_input_size', 'dev_module_cluster_num',
            'dev_module_candidate_num', 'dev_cluster_candidates',
            'dev_velo_cluster_container', 'dev_event_list'
        ]
    ],
    [
        'velo_calculate_phi_and_sort_t',
        [
            'dev_estimated_input_size', 'dev_module_cluster_num',
            'dev_velo_cluster_container', 'dev_hit_permutation'
        ]
    ],
    [
        'velo_fill_candidates_t',
        [
            'dev_velo_cluster_container', 'dev_estimated_input_size',
            'dev_module_cluster_num', 'dev_h0_candidates', 'dev_h2_candidates'
        ]
    ],
    [
        'velo_search_by_triplet_t',
        [
            'dev_velo_cluster_container', 'dev_estimated_input_size',
            'dev_module_cluster_num', 'dev_tracks', 'dev_tracklets',
            'dev_tracks_to_follow', 'dev_weak_tracks', 'dev_hit_used',
            'dev_atomics_velo', 'dev_h0_candidates', 'dev_h2_candidates',
            'dev_rel_indices'
        ]
    ],
    [
        'velo_weak_tracks_adder_t',
        [
            'dev_velo_cluster_container', 'dev_estimated_input_size',
            'dev_tracks', 'dev_weak_tracks', 'dev_hit_used', 'dev_atomics_velo'
        ]
    ],
    ['cpu_velo_prefix_sum_number_of_tracks_t', ['dev_atomics_velo']],
    [
        'velo_copy_track_hit_number_t',
        ['dev_tracks', 'dev_atomics_velo', 'dev_velo_track_hit_number']
    ],
    [
        'cpu_velo_prefix_sum_number_of_track_hits_t',
        ['dev_velo_track_hit_number']
    ],
    [
        'velo_consolidate_tracks_t',
        [
            'dev_atomics_velo', 'dev_tracks', 'dev_velo_track_hit_number',
            'dev_velo_cluster_container', 'dev_estimated_input_size',
            'dev_velo_track_hits', 'dev_velo_states',
            'dev_accepted_velo_tracks'
        ]
    ],
    [
        'velo_kalman_fit_t',
        [
            'dev_atomics_velo', 'dev_velo_track_hit_number',
            'dev_velo_track_hits', 'dev_velo_states',
            'dev_velo_kalman_beamline_states'
        ]
    ],
    [
        'pv_beamline_extrapolate_t',
        [
            'dev_velo_kalman_beamline_states', 'dev_atomics_velo',
            'dev_velo_track_hit_number', 'dev_pvtracks', 'dev_pvtrack_z'
        ]
    ],
    [
        'pv_beamline_histo_t',
        [
            'dev_atomics_velo', 'dev_velo_track_hit_number', 'dev_pvtracks',
            'dev_zhisto'
        ]
    ],
    [
        'pv_beamline_peak_t',
        ['dev_zhisto', 'dev_zpeaks', 'dev_number_of_zpeaks']
    ],
    [
        'pv_beamline_calculate_denom_t',
        [
            'dev_atomics_velo', 'dev_velo_track_hit_number', 'dev_pvtracks',
            'dev_zpeaks', 'dev_number_of_zpeaks', 'dev_pvtracks_denom'
        ]
    ],
    [
        'pv_beamline_multi_fitter_t',
        [
            'dev_atomics_velo', 'dev_velo_track_hit_number', 'dev_pvtracks',
            'dev_zpeaks', 'dev_number_of_zpeaks', 'dev_multi_fit_vertices',
            'dev_number_of_multi_fit_vertices', 'dev_pvtracks_denom',
            'dev_pvtrack_z'
        ]
    ],
    [
        'pv_beamline_cleanup_t',
        [
            'dev_multi_fit_vertices', 'dev_number_of_multi_fit_vertices',
            'dev_multi_final_vertices', 'dev_number_of_multi_final_vertices'
        ]
    ],
    [
        'ut_calculate_number_of_hits_t',
        [
            'dev_ut_raw_input', 'dev_ut_raw_input_offsets',
            'dev_ut_hit_offsets', 'dev_event_list'
        ]
    ],
    ['cpu_ut_prefix_sum_number_of_hits_t', ['dev_ut_hit_offsets']],
    [
        'ut_pre_decode_t',
        [
            'dev_ut_raw_input', 'dev_ut_raw_input_offsets', 'dev_ut_hits',
            'dev_ut_hit_offsets', 'dev_ut_hit_count', 'dev_event_list'
        ]
    ],
    [
        'ut_find_permutation_t',
        ['dev_ut_hits', 'dev_ut_hit_offsets', 'dev_ut_hit_permutations']
    ],
    [
        'ut_decode_raw_banks_in_order_t',
        [
            'dev_ut_raw_input', 'dev_ut_raw_input_offsets', 'dev_ut_hits',
            'dev_ut_hit_offsets', 'dev_ut_hit_permutations', 'dev_event_list'
        ]
    ],
    [
        'ut_search_windows_t',
        [
            'dev_ut_hits', 'dev_ut_hit_offsets', 'dev_atomics_velo',
            'dev_velo_track_hit_number', 'dev_velo_track_hits',
            'dev_velo_states', 'dev_ut_windows_layers',
            'dev_accepted_velo_tracks', 'dev_ut_active_tracks'
        ]
    ],
    [
        'compass_ut_t',
        [
            'dev_ut_hits', 'dev_ut_hit_offsets', 'dev_atomics_velo',
            'dev_velo_track_hit_number', 'dev_velo_states', 'dev_ut_tracks',
            'dev_atomics_ut', 'dev_ut_active_tracks', 'dev_ut_windows_layers',
            'dev_accepted_velo_tracks'
        ]
    ],
    ['cpu_ut_prefix_sum_number_of_tracks_t', ['dev_atomics_ut']],
    [
        'ut_copy_track_hit_number_t',
        ['dev_ut_tracks', 'dev_atomics_ut', 'dev_ut_track_hit_number']
    ],
    ['cpu_ut_prefix_sum_number_of_track_hits_t', ['dev_ut_track_hit_number']],
    [
        'ut_consolidate_tracks_t',
        [
            'dev_ut_hits', 'dev_ut_hit_offsets', 'dev_ut_track_hits',
            'dev_atomics_ut', 'dev_ut_track_hit_number', 'dev_ut_x',
            'dev_ut_z', 'dev_ut_tx', 'dev_ut_qop', 'dev_ut_track_velo_indices',
            'dev_ut_tracks'
        ]
    ],
    [
        'scifi_calculate_cluster_count_v4_t',
        [
            'dev_scifi_raw_input', 'dev_scifi_raw_input_offsets',
            'dev_scifi_hit_count', 'dev_event_list'
        ]
    ],
    ['cpu_scifi_prefix_sum_number_of_hits_t', ['dev_scifi_hit_count']],
    [
        'scifi_pre_decode_v4_t',
        [
            'dev_scifi_raw_input', 'dev_scifi_raw_input_offsets',
            'dev_scifi_hit_count', 'dev_scifi_hits', 'dev_event_list'
        ]
    ],
    [
        'scifi_raw_bank_decoder_v4_t',
        [
            'dev_scifi_raw_input', 'dev_scifi_raw_input_offsets',
            'dev_scifi_hit_count', 'dev_scifi_hits', 'dev_event_list'
        ]
    ],
    [
        'scifi_direct_decoder_v4_t',
        [
            'dev_scifi_raw_input', 'dev_scifi_raw_input_offsets',
            'dev_scifi_hit_count', 'dev_scifi_hits', 'dev_event_list'
        ]
    ],
    [
        'lf_search_initial_windows_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_velo',
            'dev_velo_track_hit_number', 'dev_velo_states', 'dev_atomics_ut',
            'dev_ut_track_hit_number', 'dev_ut_x', 'dev_ut_tx', 'dev_ut_z',
            'dev_ut_qop', 'dev_ut_track_velo_indices', 'dev_ut_states',
            'dev_scifi_lf_initial_windows', 'dev_scifi_lf_process_track'
        ]
    ],
    [
        'lf_triplet_seeding_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_ut',
            'dev_ut_qop', 'dev_scifi_lf_initial_windows', 'dev_ut_states',
            'dev_ut_track_hit_number', 'dev_ut_track_velo_indices',
            'dev_atomics_velo', 'dev_velo_states',
            'dev_scifi_lf_process_track', 'dev_scifi_lf_found_triplets',
            'dev_scifi_lf_number_of_found_triplets'
        ]
    ],
    [
        'lf_triplet_keep_best_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_ut',
            'dev_scifi_lf_tracks', 'dev_scifi_lf_atomics',
            'dev_scifi_lf_initial_windows', 'dev_scifi_lf_process_track',
            'dev_scifi_lf_found_triplets',
            'dev_scifi_lf_number_of_found_triplets',
            'dev_scifi_lf_total_number_of_found_triplets'
        ]
    ],
    [
        'lf_calculate_parametrization_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_velo',
            'dev_velo_track_hit_number', 'dev_velo_states', 'dev_atomics_ut',
            'dev_ut_track_hit_number', 'dev_ut_track_velo_indices',
            'dev_ut_qop', 'dev_scifi_lf_tracks', 'dev_scifi_lf_atomics',
            'dev_scifi_lf_parametrization'
        ]
    ],
    [
        'lf_extend_tracks_x_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_ut',
            'dev_scifi_lf_tracks', 'dev_scifi_lf_atomics',
            'dev_scifi_lf_initial_windows', 'dev_scifi_lf_parametrization'
        ]
    ],
    [
        'lf_extend_tracks_uv_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_ut',
            'dev_scifi_lf_tracks', 'dev_scifi_lf_atomics', 'dev_ut_states',
            'dev_scifi_lf_initial_windows', 'dev_scifi_lf_parametrization'
        ]
    ],
    [
        'lf_quality_filter_length_t',
        [
            'dev_atomics_ut', 'dev_scifi_lf_tracks', 'dev_scifi_lf_atomics',
            'dev_scifi_lf_length_filtered_tracks',
            'dev_scifi_lf_length_filtered_atomics',
            'dev_scifi_lf_parametrization',
            'dev_scifi_lf_parametrization_length_filter'
        ]
    ],
    [
        'lf_quality_filter_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_atomics_ut',
            'dev_scifi_lf_length_filtered_tracks',
            'dev_scifi_lf_length_filtered_atomics', 'dev_atomics_scifi',
            'dev_scifi_tracks', 'dev_scifi_lf_parametrization_length_filter',
            'dev_scifi_lf_y_parametrization_length_filter',
            'dev_scifi_lf_parametrization_consolidate', 'dev_ut_states',
            'dev_velo_states', 'dev_atomics_velo', 'dev_velo_track_hit_number',
            'dev_ut_track_velo_indices'
        ]
    ],
    ['cpu_scifi_prefix_sum_number_of_tracks_t', ['dev_atomics_scifi']],
    [
        'scifi_copy_track_hit_number_t',
        [
            'dev_atomics_ut', 'dev_scifi_tracks', 'dev_atomics_scifi',
            'dev_scifi_track_hit_number'
        ]
    ],
    [
        'cpu_scifi_prefix_sum_number_of_track_hits_t',
        ['dev_scifi_track_hit_number']
    ],
    [
        'scifi_consolidate_tracks_t',
        [
            'dev_scifi_hits', 'dev_scifi_hit_count', 'dev_scifi_track_hits',
            'dev_atomics_scifi', 'dev_scifi_track_hit_number', 'dev_scifi_qop',
            'dev_scifi_states', 'dev_scifi_track_ut_indices', 'dev_atomics_ut',
            'dev_scifi_tracks', 'dev_scifi_lf_parametrization_consolidate'
        ]
    ],
    [
        'muon_pre_decoding_t',
        [
            'dev_event_list', 'dev_muon_raw', 'dev_muon_raw_offsets',
            'dev_muon_raw_to_hits',
            'dev_storage_station_region_quarter_offsets',
            'dev_storage_tile_id', 'dev_storage_tdc_value', 'dev_atomics_muon'
        ]
    ],
    [
        'cpu_muon_prefix_sum_storage_t',
        ['dev_storage_station_region_quarter_offsets']
    ],
    [
        'muon_sort_station_region_quarter_t',
        [
            'dev_storage_tile_id', 'dev_storage_tdc_value', 'dev_atomics_muon',
            'dev_permutation_srq'
        ]
    ],
    [
        'muon_add_coords_crossing_maps_t',
        [
            'dev_storage_station_region_quarter_offsets',
            'dev_storage_tile_id', 'dev_storage_tdc_value', 'dev_atomics_muon',
            'dev_muon_hits', 'dev_muon_raw_to_hits',
            'dev_station_ocurrences_offset', 'dev_muon_compact_hit'
        ]
    ],
    ['cpu_muon_prefix_sum_station_t', ['dev_station_ocurrences_offset']],
    [
        'muon_sort_by_station_t',
        [
            'dev_storage_tile_id', 'dev_storage_tdc_value', 'dev_atomics_muon',
            'dev_permutation_station', 'dev_muon_hits',
            'dev_station_ocurrences_offset', 'dev_muon_compact_hit',
            'dev_muon_raw_to_hits'
        ]
    ],
    [
        'is_muon_t',
        [
            'dev_atomics_scifi', 'dev_scifi_track_hit_number', 'dev_scifi_qop',
            'dev_scifi_states', 'dev_scifi_track_ut_indices', 'dev_muon_hits',
            'dev_muon_track_occupancies', 'dev_is_muon'
        ]
    ],
    [
        'kalman_velo_only_t',
        [
            'dev_atomics_velo', 'dev_velo_track_hit_number',
            'dev_velo_track_hits', 'dev_atomics_ut', 'dev_ut_track_hit_number',
            'dev_ut_qop', 'dev_ut_track_velo_indices', 'dev_atomics_scifi',
            'dev_scifi_track_hit_number', 'dev_scifi_qop', 'dev_scifi_states',
            'dev_scifi_track_ut_indices', 'dev_kf_tracks'
        ]
    ],
    [
        'kalman_pv_ipchi2_t',
        [
            'dev_kf_tracks', 'dev_atomics_scifi', 'dev_scifi_track_hit_number',
            'dev_scifi_track_hits', 'dev_scifi_qop', 'dev_scifi_states',
            'dev_scifi_track_ut_indices', 'dev_multi_fit_vertices',
            'dev_number_of_multi_fit_vertices', 'dev_kalman_pv_ipchi2',
            'dev_is_muon'
        ]
    ],
    ['cpu_sv_prefix_sum_offsets_t', ['dev_sv_offsets', 'dev_atomics_scifi']],
    [
        'fit_secondary_vertices_t',
        [
            'dev_kf_tracks', 'dev_atomics_scifi', 'dev_scifi_track_hit_number',
            'dev_scifi_qop', 'dev_scifi_states', 'dev_scifi_track_ut_indices',
            'dev_multi_fit_vertices', 'dev_number_of_multi_fit_vertices',
            'dev_kalman_pv_ipchi2', 'dev_sv_offsets', 'dev_secondary_vertices'
        ]
    ],
    [
        'run_hlt1_t',
        [
            'dev_kf_tracks', 'dev_secondary_vertices', 'dev_atomics_scifi',
            'dev_sv_offsets', 'dev_one_track_results', 'dev_two_track_results',
            'dev_single_muon_results', 'dev_disp_dimuon_results',
            'dev_high_mass_dimuon_results', 'dev_dimuon_soft_results'
        ]
    ],
    [
        'prepare_raw_banks_t',
        [
            'dev_atomics_scifi', 'dev_sv_offsets', 'dev_one_track_results',
            'dev_two_track_results', 'dev_single_muon_results',
            'dev_disp_dimuon_results', 'dev_high_mass_dimuon_results',
            'dev_dec_reports', 'dev_number_of_passing_events',
            'dev_passing_event_list'
        ]
    ],
]
