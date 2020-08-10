#!/usr/bin/python3
import sys
import os
import re
import traceback
import operator
import csv
from group_algos import group_algos
from optparse import OptionParser
"""
Produces a plot of the performance breakdown of the sequence under execution
"""


def main(argv):
    global final_msg
    parser = OptionParser()
    parser.add_option(
        '-d',
        '--dir',
        dest='output_directory',
        help='The directory to scan for build_* directories')
    parser.add_option(
        '-f',
        '--file_pattern',
        dest='file_pattern',
        default='profiler_output.txt',
        help=
        'The file name to look for profiler data in each build_ directoy. default: profiler_output.txt'
    )

    (options, args) = parser.parse_args()

    if options.output_directory is None:
        parser.print_help()
        print('Please specify an input directory')
        return

    try:
        dirs = []
        files = os.listdir(options.output_directory)

    except:
        print('Failed to read profiler output directory: %s' % options.dir)
        traceback.print_exc()
        return

    dirs = []
    for file in files:
        if file.startswith('output_'):
            dirs.append(file)

    for dir in dirs:
        filepath = options.output_directory + "/" + dir + "/" + options.file_pattern
        try:
            f = open(filepath)
            s = f.read()
            f.close()
        except:
            print('Error while trying to read profiler file: %s' % filepath)
            traceback.print_exc()
            continue

        # Fetch all timings into timings[0]
        start_s = "GPU activities:"
        end_s = "API calls:"
        timings = re.findall(start_s + "(.*?)" + end_s, s, re.DOTALL)
        try:
            perf = re.findall("([0-9]+\.[0-9]+) events\/s", s)[0]
            perf = float(perf)
        except:
            print('Failed to read performance data from output')
            print(traceback.format_exc())

        try:
            runtime = re.findall("Ran test for ([0-9]+\.[0-9]+) seconds", s)[0]
            runtime = float(runtime)
        except:
            print('Failed to read runtime from output')
            print(traceback.format_exc())

        # Regexp for one line
        # Note: An algorithm line looks like:
        #  11.08%  6.47377s       700  9.2482ms  3.7639ms  15.887ms  lf_search_uv_windows(unsigned int const *, unsigned int const *, int const *, SciFi::TrackHits const *, int const *, char const *, LookingForward::Constants const *, float const *, MiniState const *, short*)
        # Note: Intended behaviour: Does *not* match nvidia calls like:
        #  0.04%  20.484ms      9100  2.2500us     832ns  16.255us  [CUDA memcpy DtoH]
        regexp_expression = ".*?([0-9]+\.[0-9]+)\%.*[um]s  ([a-zA-Z][a-zA-Z\_0-9:]+).*"

        algorithm_times = {}

        for line in timings[0].split("\n"):
            m = re.match(regexp_expression, line)
            if m:
                algorithm_times[m.group(2)] = float(m.group(1))

        # Add up everything
        full_addition = sum(algorithm_times.values())
        for k in algorithm_times.keys():
            algorithm_times[k] = 100 * algorithm_times[k] / full_addition

        output_list = sorted(
            algorithm_times.items(), key=operator.itemgetter(1), reverse=True)

        print(output_list)

        output_path = options.output_directory + "/" + dir + "/algo_breakdown.csv"
        with open(output_path, 'w') as out:
            csv_out = csv.writer(out)
            for row in output_list:
                csv_out.writerow(row)

        timings = group_algos(algorithm_times)
        print(timings)

        output_path = options.output_directory + "/" + dir + "/algo_summary.csv"
        with open(output_path, 'w') as out:
            csv_out = csv.writer(out)
            for row in timings:
                csv_out.writerow(row)


if __name__ == "__main__":
    main(sys.argv[1:])
