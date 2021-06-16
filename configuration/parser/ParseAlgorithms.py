#!/usr/bin/python3
###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

import re
import os
import sys
import codecs
from collections import OrderedDict
from AlgorithmTraversalLibClang import AlgorithmTraversal
import argparse

# Prefix folder, prepended to device / host folder
prefix_project_folder = "../"


def get_clang_so_location():
    """Function that fetches location of detected clang so."""
    import clang.cindex
    so_library = ""
    try:
        _ = clang.cindex.conf.lib.__test_undefined_symbol
    except AttributeError as error:
        so_library = error.args[0].split(":")[0]
    return so_library


class Parser():
    """A parser static class. This class steers the parsing of the
    codebase. It can be configured with the variables below."""

    # Pattern sought in every file, prior to parsing the file for an algorithm
    __algorithm_pattern_compiled = re.compile(
        "(?P<scope>Host|Device|Selection|Validation)Algorithm")

    # File extensions considered
    __sought_extensions_compiled = [
        re.compile(".*\\." + p + "$") for p in ["cuh", "h", "hpp"]
    ]

    # Folders storing device and host code
    __device_folder = "device"
    __host_folder = "host"

    @staticmethod
    def __get_filenames(folder, extensions):
        list_of_files = []
        for root, subdirs, files in os.walk(folder):
            for filename in files:
                for extension in extensions:
                    if extension.match(filename):
                        list_of_files.append(os.path.join(root, filename))
        return list_of_files

    @staticmethod
    def get_all_filenames():
        return Parser.__get_filenames(prefix_project_folder + Parser.__device_folder, Parser.__sought_extensions_compiled) + \
            Parser.__get_filenames(prefix_project_folder + Parser.__host_folder, Parser.__sought_extensions_compiled)

    @staticmethod
    def parse_all(algorithm_parser=AlgorithmTraversal()):
        """Parses all files and traverses algorithm definitions."""
        all_filenames = Parser.get_all_filenames()
        algorithms = []
        for filename in all_filenames:
            with codecs.open(filename, 'r', 'utf-8') as f:
                try:
                    s = f.read()
                    # Invoke the libTooling algorithm parser only if we find the algorithm pattern
                    has_algorithm = Parser.__algorithm_pattern_compiled.search(
                        s)
                    if has_algorithm:
                        parsed_algorithms = algorithm_parser.traverse(
                            filename, prefix_project_folder)
                        if parsed_algorithms:
                            algorithms += parsed_algorithms
                except:
                    print("Parsing file", filename, "failed")
                    raise
        return algorithms


class AllenCore():
    """Static class that generates a python representation of
    Allen algorithms."""

    @staticmethod
    def prefix(indentation_level, indent_by=2):
        return "".join([" "] * indentation_level * indent_by)

    @staticmethod
    def create_var_type(kind):
        return ("R" if "input" in kind.lower() else "W")

    @staticmethod
    def write_preamble(i=0):
        # Fetch base_types.py and include it here to make file self-contained
        s = "from PyConf.dataflow import GaudiDataHandle\n\
from AllenCore.AllenKernel import AllenAlgorithm\n\
from collections import OrderedDict\n\
from enum import Enum\n\n\n\
def algorithm_dict(*algorithms):\n\
    d = OrderedDict([])\n\
    for alg in algorithms:\n\
        d[alg.name] = alg\n\
    return d\n\n\n\
class AlgorithmCategory(Enum):\n\
    HostAlgorithm = 0\n\
    DeviceAlgorithm = 1\n\
    SelectionAlgorithm = 2\n\
    HostDataProvider = 3\n\
    DataProvider = 4\n\
    ValidationAlgorithm = 5\n\n\n"

        return s

    @staticmethod
    def write_aggregate_algorithms(algorithms, i=0):
        s = "def algorithms_with_aggregates():\n"
        i += 1
        s += AllenCore.prefix(i) + "return ["
        algorithms_with_aggregates = []
        for algorithm in algorithms:
            if len([var for var in algorithm.parameters if var.aggregate]):
                algorithms_with_aggregates.append(algorithm)
        if len(algorithms_with_aggregates):
            for algorithm in algorithms_with_aggregates:
                s += algorithm.name + ", "
            s = s[:-2]
        s += "]\n\n"
        return s

    @staticmethod
    def get_algorithm_category(name, scope):
        if name == "data_provider_t":
            return "DataProvider"
        elif name == "host_data_provider_t":
            return "HostDataProvider"
        else:
            return scope

    @staticmethod
    def write_algorithm_code(algorithm, i=0):
        s = AllenCore.prefix(
            i) + "class " + algorithm.name + "(AllenAlgorithm):\n"
        i += 1

        # Slots
        s += AllenCore.prefix(i) + "__slots__ = OrderedDict(\n"
        i += 1
        for param in algorithm.parameters:
            s += AllenCore.prefix(i) + param.typename + " = GaudiDataHandle(\"" + param.typename + "\", \"" \
                + AllenCore.create_var_type(param.kind) + "\", \"" + str(param.typedef) + "\"),\n"
        for prop in algorithm.properties:
            s += AllenCore.prefix(i) + prop.name[1:-1] + " = \"\",\n"
        s = s[:-2]
        i -= 1
        s += "\n" + AllenCore.prefix(i) + ")\n"

        # aggregates
        s += AllenCore.prefix(i) + "aggregates = ("
        i += 1
        for param in algorithm.parameters:
            if param.aggregate:
                s += "\n" + AllenCore.prefix(i) + "\"" + param.typename + "\","
        i -= 1
        s += ")\n\n"

        s += AllenCore.prefix(i) + "@staticmethod\n"
        s += AllenCore.prefix(i) + "def category():\n"
        i += 1
        s += AllenCore.prefix(
            i
        ) + f"return AlgorithmCategory.{AllenCore.get_algorithm_category(algorithm.name, algorithm.scope)}\n\n"
        i -= 1

        s += AllenCore.prefix(i) + "def __new__(self, name, **kwargs):\n"
        i += 1
        s += AllenCore.prefix(
            i) + "instance = AllenAlgorithm.__new__(self, name)\n"
        s += AllenCore.prefix(i) + "for n,v in kwargs.items():\n"
        i += 1
        s += AllenCore.prefix(i) + "setattr(instance, n, v)\n"
        i -= 1
        s += AllenCore.prefix(i) + "return instance\n\n"
        i -= 1

        s += AllenCore.prefix(i) + "@classmethod\n"
        s += AllenCore.prefix(i) + "def namespace(cls):\n"
        i += 1
        s += AllenCore.prefix(i) + "return \"" + algorithm.namespace + "\"\n\n"
        i -= 1
        s += AllenCore.prefix(i) + "@classmethod\n"
        s += AllenCore.prefix(i) + "def filename(cls):\n"
        i += 1
        s += AllenCore.prefix(i) + "return \"" + algorithm.filename + "\"\n\n"
        i -= 1
        s += AllenCore.prefix(i) + "@classmethod\n"
        s += AllenCore.prefix(i) + "def getType(cls):\n"
        i += 1
        s += AllenCore.prefix(i) + "return \"" + algorithm.name + "\"\n\n\n"

        return s


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        'Parse the Allen codebase and generate a python representation of all algorithms.'
    )

    parser.add_argument(
        'filename',
        nargs='?',
        type=str,
        default="algorithms.py",
        help='output filename')
    parser.add_argument(
        'prefix_project_folder',
        nargs='?',
        type=str,
        default="..",
        help='project location')
    args = parser.parse_args()

    prefix_project_folder = args.prefix_project_folder + "/"

    print("Parsing algorithms...")
    parsed_algorithms = Parser().parse_all()

    print("Generating " + args.filename + "...")
    allen_conf = AllenCore()
    s = allen_conf.write_preamble()
    for algorithm in parsed_algorithms:
        s += allen_conf.write_algorithm_code(algorithm)
    s += allen_conf.write_aggregate_algorithms(parsed_algorithms)

    f = open(args.filename, "w")
    f.write(s)
    f.close()

    print("File " + args.filename + " was successfully generated.")
