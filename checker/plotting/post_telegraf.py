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


def send_to_telegraf(throughput, device, options):
    session = requests.session()
    session.trust_env = False
    now = time.time()
    timestamp = int(now) * 1000000000

    telegraf_string = "AllenCIPerformance_v3,branch=%s,device=%s,sequence=%s,dataset=%s,build_options=%s " % (
        options.branch,
        device,
        options.sequence,
        options.dataset,
        options.buildopts if len(options.buildopts) > 0 else "default",
    )

    telegraf_string += "performance=%.2f " % (throughput)
    telegraf_string += " %d" % timestamp

    try:
        print("Sending telegraf string: %s" % telegraf_string)
        response = session.post(options.telegraf_url, data=telegraf_string)
        print("http response: %s" % response.headers)
    except:
        print("Failed to submit data string %s" % telegraf_string)
        print(traceback.format_exc())


"""
Send Allen throughput to grafana
"""


def main(argv):
    global final_msg
    parser = OptionParser()
    parser.add_option(
        "-f",
        "--filename",
        dest="filename",
        default=
        "devices_throughputs_hlt1_pp_default_upgrade_mc_minbias_scifi_v5_000.csv",
        help="The csv file containing the throughput and device name",
    )
    parser.add_option(
        "-b",
        "--branch",
        dest="branch",
        default="UNKNOWN",
        help="branch tag to be forwarded to telegraf/grafana",
    )
    parser.add_option(
        "-s",
        "--sequence",
        dest="sequence",
        default="UNKNOWN",
        help="sequence name tag to be forwarded to telegraf/grafana",
    )
    parser.add_option(
        "-d",
        "--dataset",
        dest="dataset",
        default="UNKNOWN",
        help="dataset to be forwarded to telegraf/grafana",
    )
    parser.add_option(
        "-o",
        "--build-options",
        dest="buildopts",
        default="",
        help="build options to be forwarded to telegraf/grafana",
    )
    parser.add_option(
        "-t",
        "--telegraf_url",
        dest="telegraf_url",
        # default='http://dcinflux01.lbdaq.cern.ch:8189/telegraf',
        # Unfortunately lhcb online names are still not resolved by CERN dns... IP address it is (at least for cern based machines)
        default="http://10.128.124.77:8189/telegraf",
        help="URL to send telegraf output to",
    )

    (options, args) = parser.parse_args()

    if options.filename is None:
        parser.print_help()
        print("Please specify an input file")
        return

    try:
        os.path.isfile(options.filename)

    except:
        print("Failed to open csv file with rates and devices: %s" %
              options.filename)
        traceback.print_exc()
        return

    with open(options.filename) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=",")
        for row in csv_reader:
            device = row[0]
            device_string = device.strip()
            device_string = device_string.replace(" ", "\ ")
            throughput = float(row[1])
            print("Device: " + device_string +
                  ", Throughput: %.2f" % (throughput))

            send_to_telegraf(throughput, device_string, options)


if __name__ == "__main__":
    main(sys.argv[1:])
