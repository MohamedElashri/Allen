#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import os
import sys
from optparse import OptionParser
from csv_plotter import (
    produce_plot,
    send_to_mattermost,
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

    # Average throughputs across all devices and complain if we are above decr % threshold
    assert len(speedup_wrt_master) > 0
    average_speedup = (sum(speedup * weights[device]
                           for device, speedup in speedup_wrt_master.items()) /
                       sum(weights.values()))
    change = average_speedup - 1.0
    print(f"Device-averaged speedup: {average_speedup}")
    print(f"               % change: {change}")
    tput_tol = AVG_THROUGHPUT_DECREASE_THRESHOLD
    if change < tput_tol:
        msg = (
            f" :warning: :eyes: **average** throughput change {change*100}% " +
            f"_exceeds_ {abs(tput_tol)} % threshold")
        print(msg)
        problems.append(msg)

    # single device throughput decrease check
    for device, speedup in speedup_wrt_master.items():
        change = speedup - 1.0
        tput_tol = DEVICE_THROUGHPUT_DECREASE_THRESHOLD / weights[device]
        print(f"{device}  speedup: {speedup}")
        print(f"{device} % change: {change*100}")
        if change < tput_tol:
            msg = (
                f":warning: :eyes: **{device}** throughput change {change*100}% "
                + f"_exceeds_ {abs(tput_tol)}% threshold")
            print(msg)
            problems.append(msg)

    return problems


def main():
    """
    Produces a combined plot of the throughput of the Allen sequence.
    """
    usage = (
        "%prog [options] <-t throughput_data_file> <-b throughput_breakdown_data_file>\n"
        +
        'Example: %prog -t throughput_data.csv -b throughput_breakdown.csv -m "http://{your-mattermost-site}/hooks/xxx-generatedkey-xxx"'
    )
    parser = OptionParser(usage=usage)
    parser.add_option(
        "-m",
        "--mattermost_url",
        default=os.environ["MATTERMOST_KEY"]
        if "MATTERMOST_KEY" in os.environ else "",
        dest="mattermost_url",
        help="The url where to post outputs generated for mattermost",
    )
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
        "-l",
        "--title",
        dest="title",
        default="",
        help="Title for your graph. (default: empty string)",
    )
    parser.add_option(
        "-j", "--job", dest="job", default="", help="Name of CI job")
    (options, args) = parser.parse_args()

    if options.mattermost_url == "":
        raise ValueError(
            "No mattermost URL was found in MATTERMOST_KEY, or passed as a command line argument."
        )

    with open(options.throughput) as csvfile:
        throughput = parse_throughput(csvfile.read(), scale=1e-3)
    with open(options.breakdown) as csvfile:
        breakdown = parse_throughput(csvfile.read(), scale=1)

    master_throughput = get_master_throughput(
        options.job, csvfile=options.throughput, scale=1e-3)
    speedup_wrt_master = {
        a: throughput.get(a, b) / b
        for a, b in master_throughput.items()
    }

    problems = check_throughput_change(speedup_wrt_master)

    throughput_text = produce_plot(
        throughput,
        master_throughput=master_throughput,
        unit="kHz",
        scale=1e-3,
        print_text=True,
    )
    breakdown_text = produce_plot(breakdown, unit="%", print_text=True)

    if options.mattermost_url is not None:
        extra_message = "\n".join(problems)
        text = f"""{options.title}:
```
{throughput_text}```
{extra_message}

Breakdown of sequence:
```
{breakdown_text}```"""
        send_to_mattermost(text, options.mattermost_url)

    if problems:
        sys.exit(7)


if __name__ == "__main__":
    main()
