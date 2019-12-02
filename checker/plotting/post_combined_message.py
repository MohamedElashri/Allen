#!/usr/bin/python3
from optparse import OptionParser
from csv_plotter import produce_plot


def main():
    '''
    Produces a combined plot of the throughput of the Allen sequence.
    '''
    usage = '%prog [options] <-t throughput_data_file> <-b throughput_breakdown_data_file>\n' + \
        'Example: %prog -t throughput_data.csv -b throughput_breakdown.csv -m "http://{your-mattermost-site}/hooks/xxx-generatedkey-xxx"'
    parser = OptionParser(usage=usage)
    parser.add_option(
        '-m',
        '--mattermost_url',
        dest='mattermost_url',
        help='The url where to post outputs generated for mattermost')
    parser.add_option("-t", dest="throughput",
                  help="CSV file containing throughput of various GPUs", metavar="FILE")
    parser.add_option("-b", dest="breakdown",
                  help="CSV file containing breakdown of throughput on one GPU", metavar="FILE")
    parser.add_option('-l',
                      '--title',
                      dest='title',
                      default='',
                      help='Title for your graph. (default: empty string)')
    
    (options, args) = parser.parse_args()

    throughput_text = produce_plot(options.throughput, unit="kHz", scale=1e-3, print_text=True)
    breakdown_text = produce_plot(options.breakdown, unit="%", print_text=True)

    text = '{"text": "%s:\n```\n%s```\n\nBreakdown of sequence:\n```\n%s```"}' % (options.title, throughput_text, throughput_breakdown)
    print(text)

    if mattermost_url is not None:
        send_to_mattermost(text, mattermost_url)


if __name__ == "__main__":
    main()
