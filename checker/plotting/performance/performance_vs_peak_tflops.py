import matplotlib.pyplot as plt
from matplotlib import font_manager

labels = ["GeForce GTX 670", "GeForce GTX 680", "GeForce GTX 1060 6GB", "GeForce GTX TITAN X", "GeForce GTX 1080 Ti", "Tesla T4", "GeForce RTX 2080 Ti", "Quadro RTX 2080 Ti", "Tesla V100 32GB"]
throughput = [5.22, 5.50, 12.74, 19.20, 30.23, 34.92, 68.36, 72.83, 78.62]
# TFLOPS taken from https://en.wikipedia.org/wiki/List_of_Nvidia_graphics_processing_units
peak_tflops = [2.460, 3.090, 4.375, 6.604, 11.340, 8.100, 13.448, 16.312, 14.028]

fig = plt.figure()
ax = fig.add_subplot(111)

font = {'family': 'serif',
        'color':  'black',
        'weight': 'normal',
        'size': 16,
        }
ticks_font = font_manager.FontProperties(family='serif', style='normal',
    size=12, weight='normal', stretch='normal')

plt.plot(peak_tflops, throughput, "o")
plt.xlabel("Theoretical 32 bit TFLOPS", fontdict=font)
plt.ylabel("Throughput [kHz]", fontdict=font)
plt.ylim(0, 85)
plt.xlim(0, 23.5)

for txt, x, y in zip(labels, peak_tflops, throughput):
    if (txt == "GeForce GTX 670"):
        ax.annotate(txt, xy=(x,y-4), size=12)
    elif (txt == "Quadro RTX 2080 Ti"):
        ax.annotate(txt, xy=(x-2,y+1), size=12)
    else:
        ax.annotate(txt, xy=(x,y+1), size=12)

for labelx, labely in zip(ax.get_xticklabels(),ax.get_yticklabels()) :
    labelx.set_fontproperties(ticks_font)
    labely.set_fontproperties(ticks_font)
    
plt.show()
