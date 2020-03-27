#!/usr/bin/python3

import re
import os
import sys
from collections import OrderedDict
from AlgorithmTraversalLibTooling import AlgorithmTraversal
from LineTraversalLibTooling import LineTraversal

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
        "(?P<scope>Host|Device)Algorithm")

    # Pattern sought in every file, prior to parsing the file for a line
    __line_pattern_compiled = re.compile("Hlt1::[\\w_]+Line")

    # File extensions considered
    __sought_extensions_compiled = [
        re.compile(".*\\." + p + "$") for p in ["cuh", "h", "hpp"]
    ]

    # Folders storing device and host code
    __device_folder = "cuda"
    __host_folder = "x86"

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
    def parse_all(algorithm_parser=AlgorithmTraversal(),
                  line_parser=LineTraversal()):
        """Parses all files and traverses algorithm and line definitions."""
        all_filenames = Parser.get_all_filenames()
        algorithms = []
        lines = []
        for filename in all_filenames:
            f = open(filename)
            try:
                s = f.read()
                f.close()
                # Invoke the libTooling algorithm parser only if we find the algorithm pattern
                has_algorithm = Parser.__algorithm_pattern_compiled.search(s)
                if has_algorithm:
                    parsed_algorithms = algorithm_parser.traverse(filename)
                    if parsed_algorithms:
                        algorithms += parsed_algorithms
                # Invoke the libTooling line parser only if we find the line pattern
                has_line = Parser.__line_pattern_compiled.search(s)
                if has_line:
                    parsed_lines = line_parser.traverse(filename)
                    if parsed_lines:
                        lines += parsed_lines
            except:
                print("Parsing file", filename, "failed")
                raise
        return algorithms, lines



class AllenConf():
    """Static class that generates a python representation of
    Allen algorithms and lines."""

    @staticmethod
    def prefix(indentation_level, indent_by=2):
        return "".join([" "] * indentation_level * indent_by)

    @staticmethod
    def create_var_type(scope):
        t = ""
        if scope == "DEVICE_INPUT":
            t = "DeviceInput"
        elif scope == "DEVICE_OUTPUT":
            t = "DeviceOutput"
        elif scope == "HOST_INPUT":
            t = "HostInput"
        elif scope == "HOST_OUTPUT":
            t = "HostOutput"
        return t

    @staticmethod
    def write_preamble(i=0):
        # Fetch base_types.py and include it here to make file self-contained
        f = open(prefix_project_folder + "/scripts/BaseTypes.py")
        s = f.read()
        f.close()
        return s

    @staticmethod
    def write_line_code(line, i=0):
        s = AllenConf.prefix(
            i) + "class " + line.name + "(" + line.line_type + "):\n"
        i += 1
        s += AllenConf.prefix(i) + "def __init__(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "self.__name=\"" + line.name + "\"\n"
        s += AllenConf.prefix(i) + "self.__filename=\"" + line.filename[len(
            prefix_project_folder):] + "\"\n"
        s += AllenConf.prefix(
            i) + "self.__namespace=\"" + line.namespace + "\"\n"
        i -= 1
        s += "\n"

        s += AllenConf.prefix(i) + "def filename(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__filename\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def namespace(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__namespace\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def name(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__name\n\n"
        i -= 2
        s += "\n"

        return s

    @staticmethod
    def write_algorithm_code(algorithm, i=0):
        s = AllenConf.prefix(
            i) + "class " + algorithm.name + "(" + algorithm.scope + "):\n"
        i += 1
        s += AllenConf.prefix(i) + "def __init__(self,\n"
        i += 1
        s += AllenConf.prefix(i) + "name=\"" + algorithm.name + "\""
        for var in algorithm.parameters:
            s += ",\n" \
              + AllenConf.prefix(i) + var.typename + "=" + AllenConf.create_var_type(var.kind) \
              + "(\"" + var.typename + "\", \"" + var.typedef + "\")"
        for prop in algorithm.properties:
            s += ",\n" \
              + AllenConf.prefix(i) + prop.name[1:-1] + "=Property" \
              + "(\"" + prop.typedef + "\", " \
              + "\"\", " + prop.description + ")"
        s += "):\n"
        s += AllenConf.prefix(i) + "self.__filename = \"" + algorithm.filename[
            len(prefix_project_folder):] + "\"\n"
        s += AllenConf.prefix(i) + "self.__name = name\n"
        s += AllenConf.prefix(
            i) + "self.__original_name = \"" + algorithm.name + "\"\n"
        if algorithm.threetemplate:
            s += AllenConf.prefix(i) + "self.__requires_lines = True\n"
        else:
            s += AllenConf.prefix(i) + "self.__requires_lines = False\n"
        s += AllenConf.prefix(
            i) + "self.__namespace = \"" + algorithm.namespace + "\"\n"
        s += AllenConf.prefix(i) + "self.__ordered_parameters = OrderedDict(["
        i += 1
        for var in algorithm.parameters:
            s += "\n" + AllenConf.prefix(i) + "(\"" + var.typename + "\", " + AllenConf.create_var_type(var.kind) \
              + "(" + var.typename + ", \"" + var.typedef + "\")),"
        s = s[:-1]
        if len(algorithm.parameters) > 0:
            s += "]"
        s += ")\n"
        i -= 1
        s += AllenConf.prefix(i) + "self.__ordered_properties = OrderedDict(["
        i += 1
        for prop in algorithm.properties:
            s += "\n" + AllenConf.prefix(i) + "(" + prop.name + ", Property" \
              + "(\"" + prop.typedef + "\", " \
              + "\"\", " + prop.description + ", " + prop.name[1:-1] + ")),"
        s = s[:-1]
        if len(algorithm.properties) > 0:
            s += "]"
        s += ")\n"
        i -= 1
        s += "\n"
        i -= 1

        s += AllenConf.prefix(i) + "def filename(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__filename\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def namespace(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__namespace\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def original_name(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__original_name\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def name(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__name\n\n"
        i -= 1

        s += AllenConf.prefix(i) + "def requires_lines(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__requires_lines\n\n"
        i -= 1

        for var in algorithm.parameters:
            s += AllenConf.prefix(i) + "def " + var.typename + "(self):\n"
            i += 1
            s += AllenConf.prefix(
                i
            ) + "return self.__ordered_parameters[\"" + var.typename + "\"]\n\n"
            i -= 1

        for prop in algorithm.properties:
            s += AllenConf.prefix(i) + "def " + prop.name[1:-1] + "(self):\n"
            i += 1
            s += AllenConf.prefix(
                i) + "return self.__ordered_properties[" + prop.name + "]\n\n"
            i -= 1

        s += AllenConf.prefix(i) + "def parameters(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__ordered_parameters\n"
        i -= 1
        s += "\n"

        s += AllenConf.prefix(i) + "def properties(self):\n"
        i += 1
        s += AllenConf.prefix(i) + "return self.__ordered_properties\n"
        i -= 1
        s += "\n"

        s += AllenConf.prefix(i) + "def __repr__(self):\n"
        i += 1
        s += AllenConf.prefix(
            i
        ) + "s = self.__original_name + \" \\\"\" + self.__name + \"\\\" (\"\n"
        s += AllenConf.prefix(
            i) + "for k, v in iter(self.__ordered_parameters.items()):\n"
        i += 1
        s += AllenConf.prefix(
            i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
        i -= 1
        s += AllenConf.prefix(
            i) + "for k, v in iter(self.__ordered_properties.items()):\n"
        i += 1
        s += AllenConf.prefix(
            i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
        i -= 1
        s += AllenConf.prefix(i) + "s = s[:-2]\n"
        s += AllenConf.prefix(i) + "s += \")\"\n"
        s += AllenConf.prefix(i) + "return s\n"
        s += "\n\n"

        return s


class GaudiAllenConf():
    """Static class that generates a python representation of
    Allen algorithms and lines."""

    @staticmethod
    def prefix(indentation_level, indent_by=2):
        return "".join([" "] * indentation_level * indent_by)

    @staticmethod
    def create_var_type(scope):
        t = ""
        if scope == "DEVICE_INPUT":
            t = "R"
        elif scope == "DEVICE_OUTPUT":
            t = "W"
        elif scope == "HOST_INPUT":
            t = "R"
        elif scope == "HOST_OUTPUT":
            t = "W"
        return t

    @staticmethod
    def write_preamble(i=0):
        # Fetch base_types.py and include it here to make file self-contained
        s = "from GaudiKernel.GaudiHandles import *\n" + \
            "from GaudiKernel.DataObjectHandleBase import DataObjectHandleBase\n" + \
            "from GaudiKernel.Proxy.Configurable import *\n\n\n"
        return s

    @staticmethod
    def write_line_code(line, i=0):
        s = GaudiAllenConf.prefix(
            i) + "class " + line.name + "(" + line.line_type + "):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "def __init__(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "self.__name=\"" + line.name + "\"\n"
        s += GaudiAllenConf.prefix(i) + "self.__filename=\"" + line.filename[len(
            prefix_project_folder):] + "\"\n"
        s += GaudiAllenConf.prefix(
            i) + "self.__namespace=\"" + line.namespace + "\"\n"
        i -= 1
        s += "\n"

        s += GaudiAllenConf.prefix(i) + "def filename(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "return self.__filename\n\n"
        i -= 1

        s += GaudiAllenConf.prefix(i) + "def namespace(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "return self.__namespace\n\n"
        i -= 1

        s += GaudiAllenConf.prefix(i) + "def name(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "return self.__name\n\n"
        i -= 2
        s += "\n"

        return s

    @staticmethod
    def write_algorithm_code(algorithm, i=0):
        s = GaudiAllenConf.prefix(i) + "class " + algorithm.name + "(ConfigurableAlgorithm):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "__slots__ = dict(\n"
        i += 1
        for param in algorithm.parameters:
            s += GaudiAllenConf.prefix(i) + param.typename + " = DataObjectHandleBase(\"" + param.typename + "\", \"" \
                + GaudiAllenConf.create_var_type(param.kind) + "\", \"" + str(param.typedef) + "\"),\n"
        s = s[:-2]
        i -= 1
        s += "\n" + GaudiAllenConf.prefix(i) + ")\n\n"
        s += GaudiAllenConf.prefix(i) + "def __init__(self, name = Configurable.DefaultName, **kwargs):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "super(" + algorithm.name + ", self).__init__(name)\n" \
            + GaudiAllenConf.prefix(i) + "for n,v in kwargs.items():\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "setattr(self, n, v)\n\n"
        i -= 2
        s += GaudiAllenConf.prefix(i) + "def getDlls(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "return \"Allen\"\n\n"
        i -= 1
        s += GaudiAllenConf.prefix(i) + "def getType(self):\n"
        i += 1
        s += GaudiAllenConf.prefix(i) + "return \"" + algorithm.name + "\"\n\n\n"

        return s



if __name__ == '__main__':
    filename = "algorithms.py"
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        if len(sys.argv) > 2:
            prefix_project_folder = sys.argv[2] + "/"

    print("Parsing algorithms...")
    parsed_algorithms, parsed_lines = Parser().parse_all()

    print("Generating " + filename + "...")
    s = GaudiAllenConf().write_preamble()
    for algorithm in parsed_algorithms:
        s += GaudiAllenConf().write_algorithm_code(algorithm)

    # for line in parsed_lines:
    #     s += GaudiAllenConf().write_line_code(line)

    f = open(filename, "w")
    f.write(s)
    f.close()

    print("File " + filename + " was successfully generated.")
