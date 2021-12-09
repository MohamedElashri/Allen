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


def main():
    """
    Produces a combined plot of the throughput of the Allen sequence.
    """
    usage = (
        "%prog [options] <-t throughput_data_file> <-b throughput_breakdown_data_file>\n"
        + 'Example: %prog -t throughput_data.csv -b throughput_breakdown.csv -m "http://{your-mattermost-site}/hooks/xxx-generatedkey-xxx"'
    )
    parser = OptionParser(usage=usage)
    parser.add_option(
        "-m",
        "--mattermost_url",
        default=os.environ["MATTERMOST_KEY"] if "MATTERMOST_KEY" in os.environ else "",
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

    parser.add_option("-j", "--job", dest="job", default="", help="Name of CI job")

    parser.add_option(
        "--allowed-average-decrease",
        dest="min_avg_tput_change",
        default=-2.5,
        help="Max tolerated average throughput decrease (%).",
    )

    parser.add_option(
        "--allowed-single-decrease",
        dest="min_single_tput_change",
        default=-5.0,
        help="Max tolerated single-device throughput decrease (%).",
    )

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
        options.job, csvfile=options.throughput, scale=1e-3
    )

    speedup_wrt_master = {
        a: throughput.get(a, b) / b for a, b in master_throughput.items()
    }

    # Average throughputs across all devices and complain if we are above decr % threshold
    avg_throughput_decr = False
    single_throughput_decr = False
    extra_messages = ""

    n_dev = len(speedup_wrt_master.values())
    if n_dev > 0:
        average_speedup = sum(speedup_wrt_master.values()) / n_dev
        change = (average_speedup - 1.0) * 100.0

        print(f"Device-averaged speedup: {average_speedup}")
        print(f"               % change: {change}")

        extra_messages = f"*Device-averaged speedup (% change):* {average_speedup:.2f}  ({change:.2f} %)"

        tput_tol = float(options.min_avg_tput_change)

        if change < tput_tol:
            print("*** Average throughput decrease above threshold.")
            extra_messages += f" :warning: :eyes: decrease _exceeds_ {abs(float(tput_tol))} % threshold\n"
            avg_throughput_decr = True
    else:
        print("No throughput reference available")
        extra_messages = f":warning: No reference available for comparison."

    # single device throughput decrease check
    extra_messages += "\n" if len(extra_messages) > 0 else ""
    tput_tol = float(options.min_single_tput_change)

    for device, speedup in speedup_wrt_master.items():
        change = (speedup - 1.0) * 100.0
        print(f"{device}  speedup: {speedup}")
        print(f"{device} % change: {change}")

        if change < tput_tol:
            print(f"*** {device} Single-device throughput decrease above threshold.")
            extra_messages += f":warning: :eyes: **{device}** throughput decrease _exceeds_ {abs(float(tput_tol))} % threshold\n"
            avg_throughput_decr = True

    throughput_text = produce_plot(
        throughput,
        master_throughput=master_throughput,
        unit="kHz",
        scale=1e-3,
        print_text=True,
    )
    breakdown_text = produce_plot(breakdown, unit="%", print_text=True)

    text = f"{options.title}:\n```\n{throughput_text}```\n{extra_messages}\n\nBreakdown of sequence:\n```\n{breakdown_text}```"

    if options.mattermost_url is not None:
        send_to_mattermost(text, options.mattermost_url)

    if avg_throughput_decr:
        sys.exit(5)

    if single_throughput_decr:
        sys.exit(6)


if __name__ == "__main__":
    main()
