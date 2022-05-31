#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

import sys
from tabulate import tabulate
from optparse import OptionParser
from csv_plotter import (
    get_master_throughput,
    parse_throughput,
)

DEVICE_THROUGHPUT_DECREASE_THRESHOLD = -0.075
AVG_THROUGHPUT_DECREASE_THRESHOLD = -0.025
# By default weights are 1.0 if not specified.
# When a weight is less than one for a device, it will contribute
# correspondlingly less to the average and its individual threshold will
# be relaxed.
DEVICE_WEIGHTS = {
    "MI100": 0.5,
}


def check_throughput_change(speedup_wrt_master):
    problems = []
    weights = {
        device: DEVICE_WEIGHTS.get(device, 1.0)
        for device in speedup_wrt_master
    }

    if len(speedup_wrt_master) == 0:
        return problems

    # single device throughput decrease check
    single_device_table = []
    for device, speedup in speedup_wrt_master.items():
        change = speedup - 1.0
        tput_tol = DEVICE_THROUGHPUT_DECREASE_THRESHOLD / weights[device]
        # print(f"{device:<30}  speedup (% change): {speedup:.2f}x ({change*100:.2f}%)")

        status = "OK"
        if change < tput_tol:
            msg = (
                f":warning: :eyes: **{device}** throughput change {change*100:.2f}% "
                + f"_exceeds_ {abs(tput_tol)*100}% threshold")
            print(msg)
            problems.append(msg)
            status = "DECREASED"
        
        single_device_table.append(
            [device, f"{speedup:.2f}x", f"{change*100:.2f}%", status]
        )
    print()
    print(
        tabulate(
            single_device_table, headers=[
                "Device", "Speedup", r"% change", "status"
            ],
        )
    )
    print()
    
    # Average throughputs across all devices and complain if we are above decr % threshold
    average_speedup = (sum(speedup * weights[device]
                           for device, speedup in speedup_wrt_master.items()) /
                       sum(weights.values()))
    change = average_speedup - 1.0
    print(f"Device-averaged speedup: {average_speedup:.2f}x")
    print(f"               % change: {change*100:.2f}%")
    tput_tol = AVG_THROUGHPUT_DECREASE_THRESHOLD
    avg_tput_status = "OK"
    if change < tput_tol:
        msg = (
            f" :warning: :eyes: **average** throughput change {change*100:.2f}% " +
            f"_exceeds_ {abs(tput_tol)*100} % threshold")
        problems.append(msg)
        avg_tput_status = "DECREASED"

    print(f"                 status: {avg_tput_status}")
    
    print()

    print("Pass\n" if not problems else "FAIL\n")

    return problems


def main():
    """
    Compares the throughput of the Allen sequence against the latest reference in ref master against the provided data.
    """
    usage = (
        "%prog [options] <-t throughput_data_file>\n"
        +
        'Example: %prog -t throughput_data.csv'
    )
    parser = OptionParser(usage=usage)
    parser.add_option(
        "-t",
        dest="throughput",
        help="CSV file containing throughput of various GPUs",
        metavar="FILE",
    )
    parser.add_option(
        "-b",
        dest="breakdown",
        help="CSV file containing breakdown of throughput on one GPU",
        metavar="FILE",
    )
    parser.add_option(
        "-j", "--job", dest="job", default="", help="Name of CI job")
    (options, args) = parser.parse_args()

    with open(options.throughput) as csvfile:
        throughput = parse_throughput(csvfile, scale=1e-3)

    master_throughput = get_master_throughput(
        options.job, csvfile=options.throughput, scale=1e-3)
    speedup_wrt_master = {
        a: throughput.get(a, b) / b
        for a, b in master_throughput.items()
    }

    problems = check_throughput_change(speedup_wrt_master)

    if problems:
        sys.exit(7)


if __name__ == "__main__":
    main()
