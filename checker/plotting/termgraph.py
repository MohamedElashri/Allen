#!/usr/bin/python3
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

import math

#######################################################################
# From termgraph
# https://github.com/mkaz/termgraph/
#######################################################################


class TermGraph:
    def __init__(self, tg_width=50, tg_format='{:<4.2f}', delim=',', tick='█', sm_tick='▌', suffix="", x_max = 50):
        self.tg_width = tg_width
        self.tg_format = tg_format
        self.DELIM = delim
        self.TICK = tick
        self.SM_TICK = sm_tick
        self.text = ""
        self.suffix = suffix
        self.x_max = x_max
        self.big_tick = "┼"
        self.small_tick = "┴"
        self.horiz = "─"
        self.label_length = 0
 
    def find_max_label_length(self, labels):
        """Return the maximum length for the labels."""
        length = 0
        for i in range(len(labels)):
            if len(labels[i]) > length:
                length = len(labels[i])

        self.label_length = length
        return length # Yes, yes, i know ...

    def getScale(self, data):
        # min_dat = find_min(data)
        self.min_dat = min(data)
        if max(data) < self.x_max:
            self.max_dat = self.x_max
        else:
            self.max_dat = max(data)
        #epsilon = (maximum - minimum) / 1e6
        #maximum += epsilon
        #minimum -= epsilon
        rr = self.max_dat - self.min_dat
        stepCount = 10
        roughStep = rr / (stepCount -1)

        goodNormalizedSteps = [1, 2, 5, 10]
        stepPower = math.pow(10, -math.floor(math.log10(abs(roughStep))))
        normalizedStep = roughStep * stepPower
        goodNormalizedStep = list(filter(lambda x: x > normalizedStep, goodNormalizedSteps))[0]
        self.step = int(goodNormalizedStep / stepPower)
        self.scaleMax = int(math.ceil(self.max_dat / self.step) * self.step)
        self.scaleMin = int(math.floor(self.min_dat / self.step) * self.step) 
        self.strlen = max(len(str(int(self.scaleMin))), len(str(int(self.scaleMax))))
        print(self.strlen)
        self.nSteps = int((self.scaleMax - self.scaleMin) / self.step)
        print(self.scaleMin, self.scaleMax, self.step, self.nSteps)

        self.tick_dist = int(self.tg_width / (self.scaleMax - self.scaleMin) * self.step / 2)
        print(self.tick_dist)
    
        self.tg_width = int(self.tick_dist * 2 * self.nSteps)
        print('Updating tg_width to: %d' % self.tg_width)
        return

    def numLen(self, num):
        return len(str(int(num)))

    def printAxis(self):
        self.text += " " * (self.label_length + 1)
        self.text += self.big_tick

        for i in range(0, self.nSteps * 2):
            self.text += self.horiz * int(self.tick_dist - 1)
            if i % 2 == 0:
                self.text += self.small_tick
            else:
                self.text += self.big_tick

        self.text += "\n"
        
        l = self.numLen(self.scaleMin)
        l = int(l/2)
        self.text += " " * (self.label_length - l - self.tick_dist + 2) 
        for i in range(self.scaleMin,  self.scaleMax + self.step, self.step):
            self.text += '{:^{width}}'.format(str(i), width = '%d' % (self.tick_dist * 2))
        self.text += "\n"

    def normalize(self, data, width):
        """Normalize the data and return it."""
      
        # We offset by the minimum if there's a negative.
        off_data = []
        if self.min_dat < 0:
            self.min_dat = abs(self.min_dat)
            for dat in data:
                off_data.append(self.min_dat + dat)
        else:
            off_data = data
        #self.max_dat += abs(self.min_dat)

        #if self.max_dat < self.x_max:
            # Don't need to normalize if the max value
            # is less than the width we allow.
            #return off_data
        #    self.max_dat = self.x_max

        # max_dat / width is the value for a single tick. norm_factor is the
        # inverse of this value
        # If you divide a number to the value of single tick, you will find how
        # many ticks it does contain basically.
        print('width: %d, max_dat: %f' % (width, self.scaleMax))
        norm_factor = width / float(self.scaleMax)
        normal_dat = []
        for dat in off_data:
            normal_dat.append(dat * norm_factor)


        return normal_dat

    def horiz_rows(self, labels, data, normal_dat):
        """Prepare the horizontal graph.
           Each row is printed through the print_row function."""
        val_min = min(data)

        for i in range(len(labels)):
            label = "{:<{x}} │".format(labels[i], x=self.find_max_label_length(labels))

            values = data[i]
            num_blocks = normal_dat[i]

            for j in range(1):
                # In Multiple series graph 1st category has label at the beginning,
                # whereas the rest categories have only spaces.
                if j > 0:
                    len_label = len(label)
                    label = ' ' * len_label
                tail = ' {} %s'.format(self.tg_format.format(values)) % self.suffix
                color = None
                # print(label, end="")
                self.text += label
                yield(values, int(num_blocks), val_min, color)
                self.text += tail + '\n'

    # Prints a row of the horizontal graph.

    def print_row(self, value, num_blocks, val_min, color):
        """A method to print a row for a horizontal graphs.
      
        i.e:
        1: ▇▇ 2
        2: ▇▇▇ 3
        3: ▇▇▇▇ 4
        """

        if num_blocks < 1 and (value >= val_min or value > 0):
            # Print something if it's not the smallest
            # and the normal value is less than one
            # sys.stdout.write(SM_TICK)
            # print(SM_TICK, end="")
            self.text += self.SM_TICK
        else:
            for _ in range(num_blocks):
                # sys.stdout.write(TICK)
                # print(TICK, end="")
                self.text += self.TICK

        for _ in range(max([num_blocks,1]), self.tg_width):
            self.text += ' '

    def chart(self, data, labels):
        # One category/Multiple series graph with same scale
        # All-together normalization
        self.text=""
        self.getScale(data)
        normal_dat = self.normalize(data, self.tg_width)
        for row in self.horiz_rows(labels, data, normal_dat):
            self.print_row(*row)
        self.printAxis()

        return self.text


#######################################################################
# Finish termgraph
#######################################################################


def main():
    g = TermGraph(suffix='Hz')
    data = [-100, 500, 0, -111, 222.324324]
    labels = ['foo', 'bar', 'banana', 'monkey', 'fish']
    print(g.chart(data, labels))


#Small test application

if __name__ == '__main__':
    main()

