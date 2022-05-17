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
from check_throughput import check_throughput_change


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
        throughput = parse_throughput(csvfile, scale=1e-3)
    with open(options.breakdown) as csvfile:
        breakdown = parse_throughput(csvfile, scale=1)

    master_throughput = get_master_throughput(
        options.job, csvfile=options.throughput, scale=1e-3)

    problems = check_throughput_change(throughput, master_throughput)

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
