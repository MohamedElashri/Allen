###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import matplotlib.pyplot as plt
from matplotlib import font_manager
import statistics

labels = [
    "GeForce GTX 670", "GeForce GTX 680", "GeForce GTX 1060 6GB",
    "GeForce GTX TITAN X", "GeForce GTX 1080 Ti", "Tesla T4",
    "GeForce RTX 2080 Ti", "Quadro RTX 6000", "Tesla V100 32GB"
]
measurements = {
    "GeForce GTX 670":
    {5.26, 5.44, 5.05, 5.41, 5.37, 5.27, 5.23, 5.34, 5.34, 5.41},
    "GeForce GTX 680":
    {5.47, 5.66, 5.26, 5.63, 5.56, 5.52, 5.48, 5.54, 5.53, 5.66},
    "GeForce GTX 1060 6GB":
    {12.17, 12.61, 11.75, 12.42, 12.28, 12.07, 11.95, 12.32, 12.31, 12.27},
    "GeForce GTX TITAN X": {
        17.98, 18.73, 17.19, 18.17, 18.03, 17.74, 17.56, 18.21, 17.92, 18.18
    },
    "GeForce GTX 1080 Ti": {
        28.70, 29.84, 27.46, 28.97, 28.77, 28.28, 28.04, 29.15, 28.61, 29.02
    },
    "Tesla T4": {
        37.86, 39.38, 36.33, 38.23, 37.95, 37.32, 36.76, 38.41, 37.81, 38.31
    },
    "GeForce RTX 2080 Ti": {
        71.30, 73.84, 68.20, 71.92, 71.64, 70.28, 69.83, 72.38, 70.98, 72.14
    },
    "Quadro RTX 6000": {
        75.10, 77.69, 72.17, 76.03, 75.59, 74.68, 73.82, 76.29, 75.05, 76.07
    },
    "Tesla V100 32GB": {
        79.32, 82.30, 76.32, 80.43, 70.90, 78.73, 77.70, 80.55, 79.43, 80.23
    }
}
throughput = []
errors = []
for label in labels:
    meas = measurements[label]
    mean = statistics.mean(meas)
    stddev = statistics.stdev(meas)
    throughput.append(mean)
    errors.append(stddev)

# TFLOPS taken from https://en.wikipedia.org/wiki/List_of_Nvidia_graphics_processing_units
peak_tflops = [
    2.460, 3.090, 4.375, 6.604, 11.340, 8.100, 13.448, 16.312, 14.028
]

fig = plt.figure()
ax = fig.add_subplot(111)

font = {
    'family': 'serif',
    'color': 'black',
    'weight': 'normal',
    'size': 16,
}
ticks_font = font_manager.FontProperties(
    family='serif', style='normal', size=12, weight='normal', stretch='normal')

plt.errorbar(peak_tflops, throughput, yerr=errors, fmt='.k')
plt.xlabel("Theoretical 32 bit TFLOPS", fontdict=font)
plt.ylabel("Throughput [kHz]", fontdict=font)
plt.ylim(0, 85)
plt.xlim(0, 24.5)

for txt, x, y in zip(labels, peak_tflops, throughput):
    if (txt == "GeForce GTX 670"):
        ax.annotate(txt, xy=(x, y - 4), size=12)
    elif (txt == "GeForce RTX 2080 Ti"):
        ax.annotate(txt, xy=(x, y - 4), size=12)
    elif (txt == "Quadro RTX 6000"):
        ax.annotate(txt, xy=(x + 0.5, y), size=12)
    else:
        ax.annotate(txt, xy=(x, y + 1), size=12)

for labelx, labely in zip(ax.get_xticklabels(), ax.get_yticklabels()):
    labelx.set_fontproperties(ticks_font)
    labely.set_fontproperties(ticks_font)

plt.show()
