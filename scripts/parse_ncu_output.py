###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import csv
import argparse

parser = argparse.ArgumentParser(
    description='Parses a csv file from a ncu report and generates a csv with a custom metric.'
)

parser.add_argument(
    '--input_filename',
    nargs='?',
    type=str,
    default="allen_report.csv",
    help='input filename')
parser.add_argument(
    '--output_filename',
    nargs='?',
    type=str,
    default="allen_report_custom_metric.csv",
    help='output filename')
args = parser.parse_args()

kernel_dict = {}
with open(args.input_filename) as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if row["Kernel Name"] not in kernel_dict:
            kernel_dict[row["Kernel Name"]] = {}
        kernel_dict[row["Kernel Name"]][row["Metric Name"]] = row

algorithm_list = []
for k in kernel_dict.keys():
    def get_metric(metric, name="Metric Value", cast_lambda=lambda x: float(x.replace(",", ""))):
        return cast_lambda(kernel_dict[k][metric][name])

    custom_metric_1 = get_metric("SM Active Cycles") * \
        get_metric("Compute (SM) Throughput")
    algorithm_list.append((k, custom_metric_1))

total_sum = sum([a[1] for a in algorithm_list])
sorted_list = sorted(algorithm_list, key=lambda x: x[1])
sorted_list.reverse()

with open(args.output_filename, "w") as f:
    f.write("Algorithm,SM Active Cycles * SM [%]\n")
    for a in sorted_list:
        f.write(f"\"{a[0]}\", {100.0 * a[1] / total_sum}\n")
