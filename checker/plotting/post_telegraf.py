#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import sys
import os
import re
import traceback
import operator
import csv
import requests
import time
from optparse import OptionParser
from group_algos import group_algos


def send_to_telegraf(performance, runtime, timings, device, options):
    session = requests.session()
    session.trust_env = False
    now = time.time()
    timestamp = int(now) * 1000000000

    telegraf_string = "AllenCIPerformance,branch=%s,device=%s,sequence=%s " % (options.branch, device, options.sequence)
    for label,timing in timings:
          print(label, timing)
          telegraf_string += '{}={:.2f},'.format(label,timing)

    telegraf_string += "performance=%.2f,runtime=%.2f " % (performance, runtime)
    telegraf_string += " %d" % timestamp

    try:
        print('Sending telegraf string: %s' % telegraf_string)
        response = session.post(options.telegraf_url, data=telegraf_string)
        #print('http response: %s' % response.headers)
    except:
        print('Failed to submit data string %s' % telegraf_string)
        print(traceback.format_exc())


"""
Produces a plot of the performance breakdown of the sequence under execution
"""
def main(argv):
    global final_msg
    parser = OptionParser()
    parser.add_option('-d', '--dir', dest='output_directory', help='The directory to scan for build_* directories')
    parser.add_option('-f', '--file_pattern', dest='file_pattern', default='profiler_output.txt',
                      help='The file name to look for profiler data in each build_ directoy. default: profiler_output.txt')
    parser.add_option('-b', '--branch', dest='branch', default = 'UNKNOWN', help='branch tag to be forwarded to telegraf/grafana')
    parser.add_option('-s', '--sequence', dest='sequence', default = 'UNKNOWN', help='sequence name tag to be forwarded to telegraf/grafana')
    parser.add_option('-t', '--telegraf_url', dest='telegraf_url', default = 'http://localhost:8186/telegraf', help='URL to send telegraf output to')


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

    for d in dirs:
        filepath = options.output_directory +"/" + d + "/" + options.file_pattern
        try:
            f = open(filepath)
            s = f.read()
            f.close()
        except:
            print('Error while trying to read profiler file: %s' % filepath)
            traceback.print_exc()
            continue

        try:
            device = d.split('_')[1]
        except:
            traceback.print_exc()
            print('Could not extract device name from directory name: %s' % d)
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
        regexp_expression = ".*?([0-9]+\.[0-9]+)\%.*[um]s  ([a-zA-Z][a-zA-Z\_0-9]+).*"

        algorithm_times = {}

        for line in timings[0].split("\n"):
            m = re.match(regexp_expression, line)
            if m:
                algorithm_times[m.group(2)] = float(m.group(1))

        output_list = sorted(algorithm_times.items(), key=operator.itemgetter(1), reverse=True)
        print('Algorithm Times:')
        print(output_list)

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

        print('Algorithm Group Times:')
        timings = group_algos(algorithm_times)

        print(timings)

        print('Throughput: %.2f' % (perf))
        print('Runtime:    %.2f' % (runtime))

        send_to_telegraf(perf, runtime, timings, device, options)

if __name__ == "__main__":
    main(sys.argv[1:])

