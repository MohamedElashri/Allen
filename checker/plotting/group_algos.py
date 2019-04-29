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

    # Convert values to percentages
    full_addition = sum(algorithm_times.values())
    for k in algorithm_times.keys():
        algorithm_times[k] = 100 * algorithm_times[k] / full_addition

    timings = [0, 0, 0, 0, 0, 0]

    for k in algorithm_times.keys():
        if k in velo_algorithms:
            timings[0] += algorithm_times[k]
        elif k in pv_algorithms:
            timings[1] += algorithm_times[k]
        elif k in ut_algorithms:
            timings[2] += algorithm_times[k]
        elif k in scifi_algorithms or "lf_" in k:
            timings[3] += algorithm_times[k]
        elif k in kalman_algorithms:
            timings[4] += algorithm_times[k]
        else:
            timings[5] += algorithm_times[k]

    timings = getTimingLabels(timings)
    output_list = sorted(timings.items(), key=operator.itemgetter(1), reverse=True)
    return output_list


