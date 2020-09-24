#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import csv
import subprocess
import os
import re

#######################################################################
# From termgraph
# https://github.com/mkaz/termgraph/
#######################################################################

tg_width = 50
tg_format = '{:<4.2f}'
DELIM = ','
TICK = '▇'
SM_TICK = '▏'


def find_max_label_length(labels):
    """Return the maximum length for the labels."""
    length = 0
    for i in range(len(labels)):
        if len(labels[i]) > length:
            length = len(labels[i])

    return length


def normalize(data, width):
    """Normalize the data and return it."""
    # min_dat = find_min(data)
    min_dat = data[-1]
    # We offset by the minimum if there's a negative.
    off_data = []
    if min_dat < 0:
        min_dat = abs(min_dat)
        for dat in data:
            off_data.append([_d + min_dat for _d in dat])
    else:
        off_data = data
    # min_dat = find_min(off_data)
    # max_dat = find_max(off_data)
    min_dat = off_data[-1]
    max_dat = off_data[0]

    if max_dat < width:
        # Don't need to normalize if the max value
        # is less than the width we allow.
        return off_data

    # max_dat / width is the value for a single tick. norm_factor is the
    # inverse of this value
    # If you divide a number to the value of single tick, you will find how
    # many ticks it does contain basically.
    norm_factor = width / float(max_dat)
    normal_dat = []
    for dat in off_data:
        normal_dat.append([_v * norm_factor for _v in dat])

    return normal_dat


def horiz_rows(labels, data, normal_dat):
    global final_msg
    """Prepare the horizontal graph.
     Each row is printed through the print_row function."""
    # val_min = find_min(data)
    val_min = data[-1]

    for i in range(len(labels)):
        label = "{:<{x}}: ".format(labels[i], x=find_max_label_length(labels))

        values = data[i]
        num_blocks = normal_dat[i]

        for j in range(1):
            # In Multiple series graph 1st category has label at the beginning,
            # whereas the rest categories have only spaces.
            if j > 0:
                len_label = len(label)
                label = ' ' * len_label
            tail = ' {}'.format(tg_format.format(values))
            color = None
            # print(label, end="")
            final_msg += label
            yield (values, int(num_blocks), val_min, color)
            final_msg += tail + 'x\n'


# Prints a row of the horizontal graph.
def print_row(value, num_blocks, val_min, colors):
    global final_msg
    """A method to print a row for a horizontal graphs.

  i.e:
  1: ▇▇ 2
  2: ▇▇▇ 3
  3: ▇▇▇▇ 4
  """

    if num_blocks < 1 and (value > val_min or value > 0):
        # Print something if it's not the smallest
        # and the normal value is less than one.
        # sys.stdout.write(SM_TICK)
        # print(SM_TICK, end="")
        final_msg += SM_TICK
    else:
        for _ in range(num_blocks):
            # sys.stdout.write(TICK)
            # print(TICK, end="")
            final_msg += TICK


def chart(data, labels):
    # One category/Multiple series graph with same scale
    # All-together normalization
    normal_dat = normalize(data, tg_width)
    for row in horiz_rows(labels, data, normal_dat):
        print_row(*row)


#######################################################################
# Finish termgraph
#######################################################################

import traceback
from optparse import OptionParser
from termgraph import TermGraph


def format_text(title, algorithm_times, options):
    # Prepare data
    final_vals = []
    final_tags = []

    keylist = sorted(algorithm_times.keys(),
                     key=lambda x: algorithm_times[x],
                     reverse=True)
    for k in keylist:
        val = algorithm_times[k]
        final_tags.append(k)
        final_vals.append(val)

    # Plot
    print(final_tags)
    print(final_vals)
    tg = TermGraph(suffix=options.unit, x_max=options.x_max)
    final_msg = tg.chart(final_vals, final_tags)

    text = '{"text": "%s\n```\n%s```"}' % (title, final_msg)
    return text


def send_to_mattermost(text, mattermost_url):
    subprocess.call([
        "curl", "-i", "-X", "POST", "-H", 'Content-Type: application/json',
        "-d", text, mattermost_url
    ])


"""
Produces a plot of the performance breakdown of the sequence under execution
"""


def main():
    usage = '%prog [options] <-d data_file>\n' + \
            'Example: %prog -d data.csv -m "http://{your-mattermost-site}/hooks/xxx-generatedkey-xxx"'
    parser = OptionParser(usage=usage)
    parser.add_option(
        '-m',
        '--mattermost_url',
        dest='mattermost_url',
        help='The url where to post outputs generated for mattermost')
    parser.add_option('-d',
                      '--data_file',
                      dest='data_file',
                      help='Path to a data file to plot')
    parser.add_option(
        '-u',
        '--unit',
        dest='unit',
        default='',
        help='A unit suffix to append to evey value. Default is an empty string'
    )
    parser.add_option(
        '-x',
        '--x_max',
        dest='x_max',
        default=50,
        help='Graph X axis is at least this many units wide. (default=50)')
    parser.add_option('-t',
                      '--title',
                      dest='title',
                      default='',
                      help='Title for your graph. (default: empty string)')
    (options, args) = parser.parse_args()

    if options.data_file is None:
        parser.print_help()

    try:
        options.x_max = float(options.x_max)
    except:
        parser.print_help()
        print('\n-x has to be a convertible floating point value!\n')
        return -1

    algorithm_times = {}
    with open(options.data_file) as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        for row in csv_reader:
            try:
                algorithm_times[row[0]] = float(row[1])
            except:
                print(traceback.format_exc())

    # Convert throughputs to speedups
    base_speed = min(algorithm_times.values())
    for k in algorithm_times.keys():
        algorithm_times[k] /= base_speed

    text = format_text(options.title, algorithm_times, options)
    print(text)
    if options.mattermost_url is not None:
        send_to_mattermost(text, options.mattermost_url)


if __name__ == "__main__":
    main()
