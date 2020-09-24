#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import sys
import matplotlib as mpl
mpl.use('Agg')

from matplotlib.ticker import FormatStrFormatter
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import numpy as np
import os
import re

# Pretty colors
colors = [
    "#CF3D1E", "#F15623", "#F68B1F", "#FFC60B", "#DFCE21", "#BCD631",
    "#95C93D", "#48B85C", "#00833D", "#00B48D", "#60C4B1", "#27C4F4",
    "#3E67B1", "#4251A3", "#59449B", "#6E3F7C", "#6A246D", "#8A4873",
    "#EB0080", "#EF58A0", "#C05A89"
]

# Output folder
output_path = "./output"
"""
Prints the usage of this script
"""


def print_usage():
    print("Usage: performance_breakdown.py <Allen invoke line>\n" + \
    "E.g. ./performance_breakdown.py ../../../build/Allen -f ../../../input/minbias -g ../../../input/detector_configuration -n 1000 -c 0")


"""
Produces a plot of the performance breakdown of the sequence under execution
"""


def main(argv):
    if (len(argv) == 0):
        print_usage()
        return 0

    try:
        os.mkdir(output_path)
    except FileExistsError:
        pass

    # Execute sequence with nvprof and save output
    print("Executing script...")
    filename = os.getcwd() + "/" + output_path + "/" + "nvprof_output.txt"
    return_value = os.system("/usr/local/cuda-10.0/bin/nvprof " +
                             " ".join(argv) + " > " + filename + " 2>&1")
    if return_value != 0:
        print("Script returned an error message.\nCheck " + filename)
        return

    f = open(filename)
    s = f.read()
    f.close()

    # Fetch all timings into timings[0]
    start_s = "GPU activities:"
    end_s = "API calls:"
    timings = re.findall(start_s + "(.*?)" + end_s, s, re.DOTALL)

    # Regexp for one line
    # Note: An algorithm line looks like:
    #  11.08%  6.47377s       700  9.2482ms  3.7639ms  15.887ms  lf_search_uv_windows(unsigned int const *, unsigned int const *, int const *, SciFi::TrackHits const *, int const *, char const *, LookingForward::Constants const *, float const *, MiniState const *, short*)
    # Note: Intended behaviour: Does *not* match nvidia calls like:
    #  0.04%  20.484ms      9100  2.2500us     832ns  16.255us  [CUDA memcpy DtoH]
    regexp_expression = ".*?([0-9]+\.[0-9]+)\%.*[um]s  ([a-zA-Z][a-zA-Z\_0-9]+).*"

    algorithm_times = {}
    for line in timings[0].split("\n"):
        m = re.match(regexp_expression, line)
        if m:
            algorithm_times[m.group(2)] = float(m.group(1))

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

    labels_order = ["Velo", "PV", "UT", "SciFi", "Kalman", "Muon", "Common"]
    timings = {
        "Velo": {
            "algorithms": velo_algorithms,
            "value": 0,
            "color": colors[6]
        },
        "PV": {
            "algorithms": pv_algorithms,
            "value": 0,
            "color": colors[16]
        },
        "UT": {
            "algorithms": ut_algorithms,
            "value": 0,
            "color": colors[12]
        },
        "SciFi": {
            "algorithms": scifi_algorithms,
            "value": 0,
            "color": colors[11]
        },
        "Muon": {
            "algorithms": muon_algorithms,
            "value": 0,
            "color": colors[18]
        },
        "Kalman": {
            "algorithms": kalman_algorithms,
            "value": 0,
            "color": colors[3]
        },
        "Common": {
            "algorithms": [],
            "value": 0,
            "color": colors[20]
        }
    }

    # Convert values to percentages
    full_addition = sum(algorithm_times.values())
    for k in algorithm_times.keys():
        algorithm_times[k] = 100 * algorithm_times[k] / full_addition

    # Order keylist by speed
    keylist = algorithm_times.keys()
    keylist = sorted(keylist, key=lambda x: algorithm_times[x], reverse=True)

    # Choose color per algorithm
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

    # Some default parameters for the figure
    figure_scale = 1.5
    scale = 2.5
    fig = plt.figure(figsize=(6 * figure_scale, 12 * figure_scale))
    ax = plt.axes()

    bar_width = 0.85
    opacity = 0.8

    # ax.xaxis.grid(True, linestyle="dashed")

    keylist_colors = []
    for k in keylist:
        found = False
        for _, v in iter(timings.items()):
            if k in v["algorithms"]:
                found = True
                keylist_colors.append(v["color"])
        if not found:
            keylist_colors.append(timings["Common"]["color"])

    values = [algorithm_times[a] for a in keylist]
    keylist_values = range(len(keylist))
    # print(keylist, values)

    ax.barh(
        keylist_values,
        values,
        align='center',
        color=keylist_colors,
        ecolor='black')
    ax.set_yticks(keylist_values)
    ax.set_yticklabels(keylist)
    ax.invert_yaxis()  # labels read top-to-bottom

    plt.tick_params(axis='both', which='major', labelsize=6 * scale)
    plt.xlabel(
        'Fraction of Allen sequence (%)', fontdict={'fontsize': 6 * scale})

    # Make the bar plot
    labels = [a for a in labels_order]
    for i in range(len(labels_order)):
        labels[i] += " (" + ("%.2f" % timings[labels_order[i]]["value"]) + "%)"

    # Custom legend
    patches = []
    for i in range(len(labels_order)):
        patches.append(
            mpatches.Patch(
                facecolor=timings[labels_order[i]]["color"], label=labels[i]))

    plt.legend(
        patches,
        labels,
        framealpha=0.8,
        loc='right',
        ncol=1,
        fontsize=6 * scale)
    """
    t = plt.text(
        0.95,
        0.05,
        "LHCb simulation,\nGPU R&D",
        horizontalalignment='right',
        transform=ax.transAxes,
        fontdict={
            'fontsize': 8 * scale,
            'style': 'italic'
        })
    """

    ax.set_xticks(range(0, int(ax.get_xlim()[1]), 1), minor=True)
    ax.xaxis.grid(which='both', linestyle="dashed")
    ax.xaxis.grid(which='minor', alpha=0.4)
    ax.xaxis.grid(which='major', alpha=1.0)

    output_filename = "allen_timing_fractions_no_prefix_sum"
    print("Producing plots in " + output_path + "/" + output_filename)

    plt.savefig(
        output_path + "/" + output_filename + ".png",
        bbox_inches='tight',
        pad_inches=0.2)
    plt.savefig(
        output_path + "/" + output_filename + ".pdf",
        bbox_inches='tight',
        pad_inches=0.2,
        transparent=True)

    plt.close()


if __name__ == "__main__":
    main(sys.argv[1:])
