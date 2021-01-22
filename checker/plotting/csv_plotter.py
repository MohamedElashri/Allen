#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import csv
import subprocess
import traceback
from optparse import OptionParser
from termgraph import TermGraph
import requests
import urllib


def get_master_throughput(job_name, scale=1.0):
    master_throughput = {}
    if job_name:
        base_url = "https://gitlab.cern.ch/lhcb/Allen/-/jobs/artifacts/master/raw/devices_throughput.csv"
        f = {"job": job_name}
        url = base_url + "?" + urllib.parse.urlencode(f)
        r = requests.get(url, allow_redirects=True)
        content = r.content.decode("utf-8")
        content_reader = csv.reader(content.splitlines())
        for row in content_reader:
            if row:
                master_throughput[row[0]] = float(row[1]) * scale
    return master_throughput


def format_text(title, plot_data, unit, x_max, master_throughput={}):
    # Prepare data
    final_vals = []
    final_tags = []

    keylist = sorted(
        plot_data.keys(), key=lambda x: plot_data[x], reverse=True)
    for k in keylist:
        val = plot_data[k]
        final_tags.append(k)
        final_vals.append(val)

    # Plot
    print(final_tags)
    print(final_vals)
    tg = TermGraph(suffix=unit, x_max=x_max)
    output = tg.chart(final_vals, final_tags)

    # Add relative throughputs if requested
    if master_throughput:
        speedup_wrt_master = {
            a: plot_data.get(a, b) / b
            for a, b in master_throughput.items()
        }
        annotated_output = ""
        for line in output.splitlines():
            for key, speedup in speedup_wrt_master.items():
                if key in line and key in plot_data:
                    annotated_output += "{} ({:.2f}x)\n".format(line, speedup)
                    break
            else:
                annotated_output += line + "\n"
        output = annotated_output

    text = '{"text": "%s:\n```\n%s```"}' % (title, output)
    return text, output


def send_to_mattermost(text, mattermost_url):
    subprocess.call([
        "curl", "-i", "-X", "POST", "-H", 'Content-Type: application/json',
        "-d", text, mattermost_url
    ])


def produce_plot(filename,
                 unit="",
                 title="",
                 x_max=10,
                 mattermost_url=None,
                 scale=1.0,
                 normalize=False,
                 print_text=True,
                 master_throughput={}):
    plot_data = {}
    with open(filename) as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        for row in csv_reader:
            try:
                plot_data[row[0]] = float(row[1]) * scale
            except:
                print(traceback.format_exc())

    # Convert throughputs to speedups
    if normalize:
        norm = min(plot_data.values())
        for k in plot_data.keys():
            plot_data[k] /= norm

    text, raw_output = format_text(
        title, plot_data, unit, x_max, master_throughput=master_throughput)
    if print_text:
        print(text)

    if mattermost_url is not None:
        send_to_mattermost(text, mattermost_url)
    else:
        return raw_output


def main():
    '''
    Produces a plot of the performance breakdown of the sequence under execution
    '''
    usage = '%prog [options] <data_file>\n' + \
            'Example: %prog data.csv -m "http://{your-mattermost-site}/hooks/xxx-generatedkey-xxx"'
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
        default=10,
        type=float,
        help='Graph X axis is at least this many units wide. (default=10)')
    parser.add_option(
        '-t',
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

    return produce_plot(
        filename=args[0],
        unit=options.unit,
        title=options.title,
        x_max=options.x_max,
        mattermost_url=options.mattermost_url,
        scale=options.scale,
        normalize=options.normalize)


if __name__ == "__main__":
    main()
