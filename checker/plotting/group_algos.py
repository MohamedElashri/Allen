#!/usr/bin/python3

import operator

def getTimingLabels(timings):
    res = {}
    labels = ["Velo", "PV", "UT", "SciFi", "Kalman", "Common"]
    for label, timing in zip(labels, timings):
        res[label] = timing

    return res


def group_algos(algorithm_times):
    # Algorithms of each sequence
    velo_algorithms = ["consolidate_velo_tracks", "copy_velo_track_hit_number", "estimate_input_size", "masked_velo_clustering", "calculate_phi_and_sort", "search_by_triplet", "fill_candidates", "weak_tracks_adder", "copy_and_prefix_sum_single_block"]
    pv_algorithms = ["pv_beamline_peak", "pv_beamline_multi_fitter", "pv_beamline_histo", "pv_beamline_extrapolate"]
    ut_algorithms = ["consolidate_ut_tracks", "copy_ut_track_hit_number", "ut_decode_raw_banks_in_order", "ut_pre_decode", "ut_find_permutation", "ut_calculate_number_of_hits", "compass_ut", "ut_search_windows"]
    scifi_algorithms = ["scifi_pre_decode_v4", "scifi_raw_bank_decoder_v4", "scifi_calculate_cluster_count_v4", "scifi_direct_decoder_v4", "consolidate_scifi_tracks", "copy_scifi_track_hit_number"]
    kalman_algorithms = ["velo_filter", "velo_kalman_fit"]

    timings = dict([(frozenset(velo_algorithms), 0), (frozenset(pv_algorithms), 0), \
        (frozenset(ut_algorithms), 0), (frozenset(scifi_algorithms), 0), \
        (frozenset(kalman_algorithms), 0), ("Common", 0)])

    full_addition = sum(algorithm_times.values())
    for algo, value in algorithm_times.items():
        found = False
        for algo_set in timings.keys():
            if algo in algo_set:
                timings[algo_set] += 100 * value / full_addition
                found = True
                break
        if not found:
            timings["Common"] += 100 * value / full_addition

    timings = getTimingLabels(timings)
    output_list = sorted(timings.items(), key=operator.itemgetter(1), reverse=True)
    return output_list


