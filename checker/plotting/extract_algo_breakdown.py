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
from group_algos import group_algos
from optparse import OptionParser
from collections import OrderedDict
"""
Produces a reduced algorithm name
"""


class AlgorithmNameParser:
    def __init__(self):
        # "velo_search_by_triplet::velo_search_by_triplet(velo_search_by_triplet::Parameters, VeloGeometry const*)"
        # "void process_line<di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters>(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters, unsigned int, float, unsigned int, char const*, unsigned int const*, unsigned int const*)"
        # "void process_line_iterate_events<passthrough_line::passthrough_line_t, passthrough_line::Parameters>(passthrough_line::passthrough_line_t, passthrough_line::Parameters, unsigned int, unsigned int, float, unsigned int, char const*, unsigned int const*, unsigned int const*)"
        algorithm_regexp_expression = "([a-zA-Z][a-zA-Z\_0-9]+::)?([a-zA-Z][a-zA-Z\_0-9]+).*"
        sel_algorithm_regexp_expression = "void process_line[a-zA-Z\_0-9]*<([a-zA-Z][a-zA-Z\_0-9]+::)?([a-zA-Z][a-zA-Z\_0-9]+).*"
        self.__algorithm_pattern = re.compile(algorithm_regexp_expression)
        self.__sel_algorithm_pattern = re.compile(
            sel_algorithm_regexp_expression)

    def parse_algorithm_name(self, full_name):
        m0 = self.__sel_algorithm_pattern.match(full_name)
        if m0:
            return m0.group(2)
        else:
            m1 = self.__algorithm_pattern.match(full_name)
            if m1:
                return m1.group(2)
            else:
                print(full_name)


"""
Produces a plot of the performance breakdown of the sequence under execution
"""


def main(argv):
    parser = OptionParser()
    parser.add_option(
        '-d', '--dir', dest='output_directory', help='The output directory')
    parser.add_option(
        '-f',
        '--filename',
        dest='filename',
        default='allen_report_gpukernsum.csv',
        help=
        'The file name of the file containing report data. default: allen_report_gpukernsum.csv'
    )

    (options, args) = parser.parse_args()

    if options.output_directory is None:
        parser.print_help()
        print('Please specify an output directory')
        return

    plot_data = OrderedDict()
    algorithm_name_parser = AlgorithmNameParser()
    with open(options.filename) as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=',')
        for i, row in enumerate(csv_reader):
            if i > 0:
                try:
                    plot_data[algorithm_name_parser.parse_algorithm_name(
                        row[6])] = float(row[0])
                except:
                    print(traceback.format_exc())

    # Iterate plot_data and produce an output csv file
    output_path = options.output_directory + "/algo_breakdown.csv"
    with open(output_path, 'w') as out:
        csv_out = csv.writer(out)
        for key, value in iter(plot_data.items()):
            csv_out.writerow([key, value])


if __name__ == "__main__":
    main(sys.argv[1:])
