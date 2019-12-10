#!/usr/bin/python

# Script to split up data by occupancy
# using raw size of SciFi raw banks as measure
# output: files lists for the different occupancy bins

import subprocess
import os
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
from matplotlib import font_manager
import numpy as np
import random

def file_len(fname):
    if (os.stat(fname).st_size == 0):
        return 0
    else:
        with open(fname) as f:
            for i, l in enumerate(f):
                pass
            return i + 1

input_directory = "/scratch/dvombruc/minbias/mag_down/"
banks_directory = input_directory + "banks/FTCluster/"
allen_dir = "/home/dvombruc/Allen/"
n_bins = 13
size_bins = [5000, 7000, 9000, 11000, 13000, 15000, 17000, 19000, 21000, 23000, 25000, 27000]
event_lists = []
for ibin in range(n_bins):
    event_lists.append([])

proc = subprocess.Popen(['ls','-Sl', banks_directory], stdout=subprocess.PIPE)
for line in proc.stdout:
    if "total" in str(line):
        continue
    split = line.split()
    size = int(split[4])
    name = split[8]
    #print('name = ',name, ', size = ', size)
    # Sort events into bins by size
    for ibin in range(n_bins):
        # underflow bin
        if (ibin == 0):
            if (size < size_bins[ibin]):
                event_lists[ibin].append(name)
        # all actual bins (no underflow or overflow)
        elif (ibin < n_bins-1):
            if (size_bins[ibin-1] <= size <= size_bins[ibin]):
                event_lists[ibin].append(name)
        # overflow bin
        elif (ibin == n_bins-1):
            if (size > size_bins[ibin-1]):
                event_lists[ibin].append(name)

# write event lists to files
file_lists_dir = allen_dir + "checker/perfscans/file_lists"
if not os.path.exists(file_lists_dir):
    os.makedirs(file_lists_dir)
for ibin in range(n_bins):
    file_name = file_lists_dir + "/file_list_bin_" + str(ibin) + ".txt"
    f = open(file_name, "w")
    for event in event_lists[ibin]:
        f.write(event.decode("utf-8")+'\n')

# randomly shuffle events within one bin
# this ensures realistic throughput measurement with the first 1000 events
for ibin in range(n_bins):
    random.shuffle(event_lists[ibin])

# Run Allen on the different occupancy events
# save throughput for every run
allen_build_dir = allen_dir + "build"
output_dir = allen_dir + "checker/perfscans/output"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)
filled_bins = []
bin_errs = []
throughput = []
n_events_array = []
for ibin in range(n_bins):
    file_name = file_lists_dir + "/file_list_bin_" + str(ibin) + ".txt"
    # only process bins with events
    n_events = file_len(file_name)
    print(n_events, 'in bin ', ibin)
    if (n_events > 1000):
        os.chdir(allen_build_dir)
        #n_events_to_process = n_events
        n_events_to_process = 1000
        stdout_file = output_dir + "/stdout_bin" + str(ibin) + ".stdout"
        command = "./Allen -f " + input_directory + " -n " + str(n_events_to_process) + " --file-list " + file_name + " -t 12 -c 0 -r 100" + " >& " + stdout_file
        print('executing Allen: ', command)
        os.system(command)
        # get throughput
        proc = subprocess.Popen(['tail','-n', '2', stdout_file], stdout=subprocess.PIPE)
        for line in proc.stdout:
            if ("events" in str(line)):
                split = line.split()
                throughput.append(float(split[0]) / 1000) # convert to kHz
                half_bin_diff = (size_bins[ibin]-size_bins[ibin-1])/2
                central_val = (size_bins[ibin] - half_bin_diff) / 1000
                print("central val = ", central_val)
                filled_bins.append(central_val)
                n_events_array.append(n_events)
                bin_errs.append(half_bin_diff/1000)
                print('added throughput measurement: ', split[0])

# Plot the result
font = {'family': 'serif',
        'color':  'black',
        'weight': 'normal',
        'size': 16,
        }
if (len(filled_bins) != len(throughput) ):
    print('Filled bins and throughput measurements do not have the same length!')
    exit()
max_throughput = max(throughput)
max_n_events = max(n_events_array)
scale = max_throughput / max_n_events
n_events_array_scaled = [i * scale for i in n_events_array]
print('max throughput = ', max_throughput)
fig, ax = plt.subplots()
throughput_plot = plt.errorbar(filled_bins, throughput, xerr=bin_errs, fmt="o")

# histogram of data volume distribution
bin_edges = []
bin_edges.append(filled_bins[0]-1)
for ibin in filled_bins:
    bin_edges.append(ibin+1)
print('# of filled bins = ', len(filled_bins), ', # of bin edges = ', len(bin_edges))
bins = np.array(bin_edges)
vals = np.array(n_events_array_scaled)
histogram = plt.fill_between(bins,np.concatenate(([0],vals)), step="pre", alpha=0.2)

plt.xlabel("SciFi raw data volume [kB]", fontdict=font)
plt.ylabel("Throughput on Tesla V100 16GB [kHz]", fontdict=font)

# Second axis
secaxy = ax.secondary_yaxis('right')
secaxy.set_ylabel(r'Number of events [a.u.]', fontdict=font)
ticks_font = font_manager.FontProperties(family='serif', style='normal',
    size=12, weight='normal', stretch='normal')
for labelx, labely, labelsecy in zip(ax.get_xticklabels(), ax.get_yticklabels(), secaxy.get_yticklabels()):
    labelx.set_fontproperties(ticks_font)
    labely.set_fontproperties(ticks_font)
    labelsecy.set_fontproperties(ticks_font)

plt.ylim(0, 175)
plt.xlim(5, 17)

# Legend
legend_font = font_manager.FontProperties(family='serif', style='normal',
    size=16, weight='normal', stretch='normal')
legend = plt.legend(['Data volume distribution','Throughput'], frameon=False, prop=legend_font, loc='lower left')



plt.show()
