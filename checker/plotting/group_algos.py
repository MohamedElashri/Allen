#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

import operator


def group_algos(algorithm_times):
    # Algorithms of each sequence
    velo_algorithms = [
        "consolidate_velo_tracks", "copy_velo_track_hit_number",
        "estimate_input_size", "masked_velo_clustering",
        "calculate_phi_and_sort", "search_by_triplet", "fill_candidates",
        "weak_tracks_adder", "copy_and_prefix_sum_single_block"
    ]
    pv_algorithms = [
        "pv_beamline_peak", "pv_beamline_multi_fitter", "pv_beamline_histo",
        "pv_beamline_extrapolate"
    ]
    ut_algorithms = [
        "consolidate_ut_tracks", "copy_ut_track_hit_number",
        "ut_decode_raw_banks_in_order", "ut_pre_decode", "ut_find_permutation",
        "ut_calculate_number_of_hits", "compass_ut", "ut_search_windows"
    ]
    scifi_algorithms = ["scifi_pre_decode_v4", "scifi_raw_bank_decoder_v4", "scifi_calculate_cluster_count_v4", "scifi_direct_decoder_v4", "consolidate_scifi_tracks", "copy_scifi_track_hit_number", \
      "lf_triplet_seeding", "lf_collect_candidates", "lf_quality_filter_x", "lf_extend_tracks_x", "lf_triplet_keep_best", "lf_search_initial_windows", "lf_fit", \
      "lf_extend_missing_x", "lf_quality_filter", "lf_search_uv_windows", "lf_extend_tracks_uv", "lf_quality_filter_length"]
    muon_algorithms = ["muon_add_coords_crossing_maps", "muon_catboost_evaluator", "muon_sort_by_station", "is_muon", "muon_sort_station_region_quarter", \
      "muon_pre_decoding", "muon_catboost_features_extraction"]
    kalman_algorithms = [
        "velo_kalman", "velo_filter", "kalman_pv_ipchi2",
        "fit_secondary_vertices", "velo_kalman_fit"
    ]

    # Order of labels
    labels_order = ["Velo", "PV", "UT", "SciFi", "Kalman", "Common"]
    timings = {
        "Velo": {
            "algorithms": velo_algorithms,
            "value": 0
        },
        "PV": {
            "algorithms": pv_algorithms,
            "value": 0
        },
        "UT": {
            "algorithms": ut_algorithms,
            "value": 0
        },
        "SciFi": {
            "algorithms": scifi_algorithms,
            "value": 0
        },
        "Muon": {
            "algorithms": muon_algorithms,
            "value": 0
        },
        "Kalman": {
            "algorithms": kalman_algorithms,
            "value": 0
        },
        "Common": {
            "algorithms": [],
            "value": 0
        },
    }
    full_addition = sum(algorithm_times.values())
    for algo, value in algorithm_times.items():
        found = False
        for key, algorithm_timing in timings.items():
            algorithms = algorithm_timing["algorithms"]
            if algo in algorithms:
                timings[key]["value"] += 100 * value / full_addition
                found = True
                break
        if not found:
            timings["Common"]["value"] += 100 * value / full_addition
    simple_timings = {k: v["value"] for k, v in timings.items()}
    output_list = sorted(
        simple_timings.items(), key=operator.itemgetter(1), reverse=True)
    return output_list
