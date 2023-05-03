###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
from sys import argv, exit
from random import Random
import math
import copy
import json
"""Script to generate a LumiSummary bank layout for a set of counters specified in
   the input files. The script produces a JSON representation of the layout, which is used
   to encode and decode the luminosity summary counters. If the PyConf module  is available
   the encoding key for the schema will also be calculated.
   See the --help option for a full list of options.

   This helper script produces an optimised JSON representation for a given collection of luminosity counters.
   Input files should contain one counter per line formatted as "CounterName MaxEntries",
   where the name may not contain white space and MaxEntries is the maximum value that the counter should be expected to contain.

   As multiple counters may be packed into a single 32-bit integer and counters may not overrun between two integers,
   the packing order of the counters must be optimised.
   The script initially implements a "first-fit decreasing" algorithm where counters are considered in descending size order
   and placed into the first available slot (adding an extra int if necessary).

   The script attempts to further optimise the schema by randomly removing a subset of the smaller counters (<16bits)
   and reinserting then in a random order. Such "mutations" are retained only if they reduce the number of ints required to store the counters.
   A schema where all of the words contain a 16-bit or larger counter cannot be further optimised so the second stage is skipped in such cases.
   The mutation is repeated a configurable number of times until a configurable packing efficiency is achieved.

   An example input file follows:

EXAMPLE
T0Low               0xffffffff
T0High              0xffffffff
BCIDLow             0xffffffff
BCIDHigh                0x3fff
BXType                       3
GEC                          1
VeloTracks                1913
VeloVertices                33
SciFiClustersS1M45         765
SciFiClustersS2M45         805
SciFiClustersS3M45        1405
SciFiClusters             7650
SciFiClustersS2M123       7590
SciFiClustersS3M123       7890
ECalET                 1072742
ECalEInnerTop          3797317
ECalEMiddleTop         1478032
ECalEOuterTop          1192952
ECalEInnerBottom       4026243
ECalEMiddleBottom      1492195
ECalEOuterBottom       1384124
MuonHitsM2R1               696
MuonHitsM2R2               593
MuonHitsM2R3               263
MuonHitsM2R4               200
MuonHitsM3R1               478
MuonHitsM3R2               212
MuonHitsM3R3               161
MuonHitsM3R4               102
MuonHitsM4R1               134
MuonHitsM4R2               108
MuonHitsM4R3               409
MuonHitsM4R4               227
EOF
"""

lumi_rand = Random("lumi_schema_generator")


class Counter:
    """A single lumi counter"""

    def __init__(self, name, maxVal):
        self.name = name
        self.size = math.floor(math.log2(maxVal)) + 1
        self.offset = 0

    def __lt__(self, other):
        return self.size < other.size


class Bucket:
    """A single 32-bit 'bucket' for storing counters"""

    def __init__(self, pos):
        self.bitsRemaining = 32
        self.pos = pos
        self.counters = []

    def addCounter(self, counter):
        """Put a counter in the bucket"""
        if counter.size > self.bitsRemaining:
            return False
        counter.offset = 32 - self.bitsRemaining
        self.bitsRemaining -= counter.size
        self.counters.append(counter)
        return True


def concatinate_lumi_schemata(schemata):
    total_size = 0
    all_counters = []
    mk_counter = lambda s,c : { 'name' : c['name'], 'offset' : 8 * s + c['offset'], 'size' : c['size'] }

    for schema in schemata:
        for counter in schema['counters']:
            all_counters.append(mk_counter(total_size, counter))
            if 'shift' in counter:
                all_counters[-1]['shift'] = counter['shift']
            if 'scale' in counter:
                all_counters[-1]['scale'] = counter['scale']

        total_size += schema['size']

    return {'version': 0, 'size': total_size, 'counters': all_counters}


class LumiSchemaGenerator:
    """Class to produce a JSON representation of a LumiSummary bank layout.
     Counter names are associated with a size and an offset within the bank.
     Multiple counters may be packed into a single 32-bit integer, however,
     a single counter may not span more than one integer.
  """

    def __init__(self,
                 inputs=[],
                 shiftsAndScales={},
                 addEncodingKey=True,
                 verbose=False):
        """Optionally, provide counters as the argument "input" in the form [(counterName1, MAXENTRIES1), (counterName2, MAXENTRIES2) ... ]
    """
        self.inputs = []
        if addEncodingKey:
            self.inputs.append(Counter("encodingKey", 0xffffffff))
        for name, maxEntry in inputs:
            self.inputs.append(Counter(name, maxEntry))
        self.buckets = []
        self.size = 0
        self.sumSizes = 0
        self.shiftsAndScales = shiftsAndScales
        self.verbose = verbose

    def readInput(self, inputFileName):
        """Append the contents of the input file to the list of requested counters.
       Input files should be formatted as follows:

       counterName1 MAXENTRIES1
       counterName2 MAXENTRIES2
       ...

       where MAXENTRIES is the maximum value that a given counter may be required to store.
       Counter names may not contain whitespace. An "encodingKey" counter will be automatically
       added to the start of the schema so must not be specified in the input.
       If no input file is given then the example from the module docstring is used.
    """
        if inputFileName == None:
            #Extract the example
            lines = open(argv[0]).readlines()
            lines = lines[lines.index("EXAMPLE\n") + 1:]
            lines = lines[:lines.index("EOF\n")]
        else:
            lines = open(inputFileName).readlines()
        for line in lines:
            line = line.split()
            if len(line) != 2:
                print("Input file, %s, is not in the correct format" %
                      (inputFileName))
                print(
                    "Expect lines of counter name and maximum value separated by white space"
                )
                print("Offending line: %s" % " ".join(line))
                exit()
            (name, maxEntry) = line
            self.inputs.append(Counter(name, int(maxEntry, 0)))
        if self.verbose:
            print("Found %d counters in %s" % (len(lines), inputFileName))

    def processWithoutOptimisation(self):
        """Pack counters into 32-bit bins sequentially without running any optimisation.
        If a counter does not fit into the current last bin a new bin is appended.
        To use this functionality set the --no-opt command line option.
     """
        self.buckets = []
        self.size = 0
        self.sumSizes = 0
        self.nInputs = len(self.inputs)
        self.pack(False)

    def process(self, mutationAttempts=10, stopThreshold=100.):
        """Pack requested counters into 32-bit bins according to 'first-fit decreasing' procedure.
       Counters are sorted in order of descending size and packed into the first available 32-bit 'bucket'.
       The schema is further optimised by randomly removing a random fraction of those counters that occupy
       less than half a bucket and attempting to re-insert them in a random order. If the number of buckets
       is reduced then the 'mutated' schema is retained. This procedure is repeated up to the specified
       number of attempts or until the efficiency achieved exceeds the specified stopping threshold.
    """
        self.buckets = []
        self.size = 0
        self.sumSizes = 0
        self.nInputs = len(self.inputs)

        self.inputs.sort(reverse=True)
        self.pack()

        #if all buckets contain a counter of 16 bits or larger then no optimisation will reduce the number of buckets
        runMutationStep = False
        for bucket in self.buckets:
            if bucket.counters[0].size < 16:
                runMutationStep = True
                break
        if runMutationStep:
            for i in range(mutationAttempts):
                if 100. * self.sumSizes / self.size >= stopThreshold:
                    if self.verbose:
                        print(
                            "Packing efficiency of %.1f%% has reached or exceeded %.1f%%"
                            % (100. * self.sumSizes / self.size,
                               stopThreshold))
                        print("Stopping mutation")
                    break
                self.mutate(lumi_rand.random())

    def pack(self, optimise=True):
        if len(self.inputs) == 0:
            return
        for counter in self.inputs:
            bucketFound = False
            if optimise:
                for bucket in self.buckets:
                    if bucket.addCounter(counter):
                        bucketFound = True
                        break
            else:
                #if packing is not being optimised then only check the last bucket
                if len(self.buckets) > 0:
                    if self.buckets[-1].addCounter(counter):
                        bucketFound = True
            if not bucketFound:
                bucket = Bucket(len(self.buckets))
                if bucket.addCounter(counter):
                    self.buckets.append(bucket)
                else:
                    print(
                        "Counter %s is too large, ensure it fits within 32 bits"
                        % counter.name)
                    exit()
            self.sumSizes += counter.size

        self.inputs = []
        bucket = self.buckets[-1]
        counter = bucket.counters[-1]
        self.sumSizes = math.ceil(self.sumSizes / 32) * 32
        self.size = math.ceil(
            (32 * bucket.pos + counter.offset + counter.size) / 32) * 32
        if self.verbose:
            print("Packed %d counters into %d bytes" % (self.nInputs,
                                                        self.size / 8.))
            print("Counter packing is %.1f%% efficient" %
                  (100 * self.sumSizes / self.size))

    def mutate(self, prob):
        if self.verbose:
            print("Mutating with a %.1f%% removal rate" % (prob * 100.))
        originalBuckets = copy.deepcopy(self.buckets)
        originalSize = self.size
        originalSumSizes = self.sumSizes
        #randomly select counters to re-insert - counters of 16 bits or larger are left intact as removing them is analogous to simply reordering buckets
        for bucket in self.buckets:
            if bucket.bitsRemaining > 0:
                for counter in list(bucket.counters):
                    if counter.size < 16 and lumi_rand.random() < prob:
                        bucket.counters.remove(counter)
                        bucket.bitsRemaining += counter.size
                        self.sumSizes -= counter.size
                        self.inputs.append(counter)
        #remove any buckets that are now empty
        runMutation = False
        for bucket in list(self.buckets):
            if len(bucket.counters) == 0:
                self.buckets.remove(bucket)
                runMutation = True
        #size can only be reduced if a bucket is removed so skip if no empty buckets
        if runMutation:
            if len(self.inputs) != 0:
                #rerun the packing with a random ordering
                if self.verbose:
                    print("repacking %d counters" % len(self.inputs))
                lumi_rand.shuffle(self.inputs)
                self.pack()
                if originalSize <= self.size:
                    if self.verbose:
                        print("No improvement, reverting mutation")
                    self.buckets = originalBuckets
                    self.size = originalSize
                    self.sumSizes = originalSumSizes
                else:
                    if self.verbose:
                        print("Improvement found, retaining mutation")
        else:
            self.inputs = []
            if self.verbose:
                print("No improvement possible, skipping mutation")
            self.buckets = originalBuckets
            self.size = originalSize
            self.sumSizes = originalSumSizes

    def getJSON(self):
        """Return a JSON representation of the lumi counter scheme."""
        mk_counter = lambda b,c : { 'name':c.name, 'offset' : 32 * b.pos + c.offset, 'size': c.size }

        counters = [
            mk_counter(bucket, counter) for bucket in self.buckets
            for counter in bucket.counters
        ]

        for c in counters:
            if c['name'] in self.shiftsAndScales:
                s_s = self.shiftsAndScales[c['name']]
                c["shift"] = s_s[0]
                c["scale"] = s_s[1]

        return {'version': 0, 'size': int(self.size / 8), 'counters': counters}

    def printJSON(self):
        """Print a JSON representation of the lumi counter scheme."""
        print("JSON representation:")

        schema = json.dumps(self.getJSON())
        print(schema)
        outputName = "output.json"
        try:
            from PyConf.filecontent_metadata import _get_hash_for_text
            schemaKey = _get_hash_for_text(schema)[:8]
            print("Encoding key: %s" % (schemaKey))
            outputName = schemaKey + ".json"
        except ModuleNotFoundError:
            print(
                "PyConf module unavailable: schema encoding key cannot be calculated"
            )

        print("Writing %s" % (outputName))
        f = open(outputName, "w")
        f.write(schema)
        f.close()

    def printHeaderFile(self):
        """Print enum values for the legacy header interface."""
        for b in self.buckets:
            for c in b.counters:
                print("%sOffset = %d," % (c.name, 32 * b.pos + c.offset))
                print("%sSize = %d," % (c.name, c.size))
        print("TotalSize = %d" % (self.size))

    def printPacking(self):
        """Print a schematic layout of the counter packing within bins."""
        print("Counter packing:")
        for bucket in self.buckets:
            c = '0'
            for counter in bucket.counters:
                print(c * counter.size, end="")
                c = chr(ord(c) + 1)
            print("X" * bucket.bitsRemaining)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default=None,
        help="Input file giving counters and maximum values")
    parser.add_argument(
        "--no-opt",
        metavar="0/1",
        nargs='?',
        const=True,
        default=False,
        help="Don't perform any optimisation")
    parser.add_argument(
        "--mutations",
        metavar="N",
        type=int,
        default=20,
        help=
        "Number of mutations to perform in the second phase of optimisation")
    parser.add_argument(
        "--stop-threshold",
        metavar="PC",
        type=float,
        default=100.,
        help=
        "Packing efficiency at which further mutation attempts should be skipped"
    )
    parser.add_argument(
        "--write-header",
        metavar="0/1",
        nargs='?',
        const=True,
        default=False,
        help="Generate a header file for the legacy enum interface")
    parser.add_argument(
        "--verbose",
        metavar="0/1",
        nargs='?',
        const=True,
        default=False,
        help="Turn on verbose printing")
    args = parser.parse_args()

    l = LumiSchemaGenerator(verbose=args.verbose)
    l.readInput(args.input)

    if args.no_opt:
        l.processWithoutOptimisation()
    else:
        l.process(args.mutations, args.stop_threshold)

    l.printPacking()
    l.printJSON()

    if args.write_header:
        l.printHeaderFile()
