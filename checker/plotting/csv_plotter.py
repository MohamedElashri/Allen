#!/usr/bin/python3
import csv
import subprocess
import traceback
from optparse import OptionParser
from termgraph import TermGraph


def format_text(title, plot_data, options):
    # Prepare data
    final_vals = []
    final_tags = []

    keylist = sorted(plot_data.keys(),
                     key=lambda x: plot_data[x],
                     reverse=True)
    for k in keylist:
        val = plot_data[k]
        final_tags.append(k)
        final_vals.append(val)

    # Plot
    print(final_tags)
    print(final_vals)
    tg = TermGraph(suffix=options.unit, x_max=options.x_max)
    output = tg.chart(final_vals, final_tags)

    text = '{"text": "%s\n```\n%s```"}' % (title, output)
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
        type=float,
        help='Graph X axis is at least this many units wide. (default=50)')
    parser.add_option('-t',
                      '--title',
                      dest='title',
                      default='',
                      help='Title for your graph. (default: empty string)')
    parser.add_option(
        '-s',
        '--scale',
        dest='scale',
        default=1.0,
        type=float,
        help='Multiply all data values by this number (default=1.0)')
    parser.add_option(
        '-n',
        '--normalize',
        dest='normalize',
        action='store_true',
        default=False,
        help='Scale numbers according to lowest value (default: False)')

    (options, args) = parser.parse_args()

    plot_data = {}
    with open(args[0]) as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        for row in csv_reader:
            try:
                plot_data[row[0]] = float(row[1]) * options.scale
            except:
                print(traceback.format_exc())

    # Convert throughputs to speedups
    if options.normalize:
        norm = min(plot_data.values())
        for k in plot_data.keys():
            plot_data[k] /= norm

    text = format_text(options.title, plot_data, options)
    print(text)
    if options.mattermost_url is not None:
        send_to_mattermost(text, options.mattermost_url)


if __name__ == "__main__":
    main()
