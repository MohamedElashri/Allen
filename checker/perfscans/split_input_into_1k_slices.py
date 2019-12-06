#!/usr/bin/python

# Script to split up data by occupancy
# using raw size of SciFi raw banks as measure
# output: files lists for the different occupancy bins

import subprocess
import os

input_directory = "/scratch/dvombruc/minbias/mag_down/"
banks_directory = input_directory + "banks/FTCluster/"
allen_dir = "/home/dvombruc/Allen/"
n_bins = 10
bin_size = 1000
event_lists = []

for ibin in range(n_bins):
    event_lists.append([])

line_count = 0
all_events = []
proc = subprocess.Popen(['ls', '-l', banks_directory], stdout=subprocess.PIPE)
for line in proc.stdout:
    if "total" in str(line):
        continue
    split = line.split()
    size = int(split[4])
    name = split[8]
    all_events.append(name)
    ++line_count
    if (line_count > n_bins * bin_size):
        break

for ibin in range(n_bins):
    for event in range(bin_size):
        event_lists[ibin].append(all_events[ibin * bin_size + event])

# write event lists to files
file_lists_dir = allen_dir + "input/minbias_split/file_lists"
if not os.path.exists(file_lists_dir):
    os.makedirs(file_lists_dir)
for ibin in range(n_bins):
    file_name = file_lists_dir + "/file_list_slice_" + str(ibin) + ".txt"
    f = open(file_name, "w")
    for event in event_lists[ibin]:
        f.write(event.decode("utf-8") + '\n')
