#!/usr/bin/python3

import re
import os
from collections import OrderedDict
from AlgorithmTraversalLibTooling import AlgorithmTraversal


class AlgorithmParse():
    __algorithm_pattern_compiled = re.compile("(?P<scope>Host|Device)Algorithm")
    __sought_extensions_compiled = [re.compile(".*\\." + p + "$") for p in ["cuh", "h", "hpp"]]
    prefix_project_folder = "../"
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
                        break
        return list_of_files

    @staticmethod
    def get_all_filenames():
        return AlgorithmParse.__get_filenames(AlgorithmParse.prefix_project_folder + AlgorithmParse.__device_folder, AlgorithmParse.__sought_extensions_compiled) + \
            AlgorithmParse.__get_filenames(AlgorithmParse.prefix_project_folder + AlgorithmParse.__host_folder, AlgorithmParse.__sought_extensions_compiled)

    @staticmethod
    def parse_all(parser=AlgorithmTraversal()):
        all_filenames = AlgorithmParse.get_all_filenames()
        algorithms = []
        for filename in all_filenames:
            f = open(filename)
            s = f.read()
            f.close()
            has_algorithm = AlgorithmParse.__algorithm_pattern_compiled.search(s)
            if has_algorithm:
                parsed_algorithms = parser.traverse(filename)
                if parsed_algorithms:
                    algorithms += parsed_algorithms
        return algorithms


class ConfGen():
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
        s = "from collections import OrderedDict\nfrom base_types import *\n\n"
        return s

    @staticmethod
    def write_line_code(line, i=0):
        s = ConfGen.prefix(
            i) + "class " + line["name"] + "(" + line["line_type"] + "Line):\n"
        i += 1
        s += ConfGen.prefix(i) + "def __init__(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "self.__name=\"" + line["name"] + "\"\n"
        s += ConfGen.prefix(i) + "self.__filename=\"" + line["filename"][len(
            AlgorithmParse().ConfGen.prefix_project_folder):] + "\"\n"
        s += ConfGen.prefix(i) + "self.__namespace=\"" + line["namespace"] + "\"\n"
        i -= 1
        s += "\n"

        s += ConfGen.prefix(i) + "def filename(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__filename\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def namespace(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__namespace\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def name(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__name\n\n"
        i -= 2
        s += "\n"

        return s

    @staticmethod
    def write_algorithm_code(algorithm, i=0):
        s = ConfGen.prefix(i) + "class " + algorithm.name + "(" + algorithm.scope + "):\n"
        i += 1
        s += ConfGen.prefix(i) + "def __init__(self,\n"
        i += 1
        s += ConfGen.prefix(i) + "name=\"" + algorithm.name + "\""
        for var in algorithm.parameters:
            s += ",\n" \
              + ConfGen.prefix(i) + var.typename + "=" + ConfGen.create_var_type(var.kind) \
              + "(\"" + var.typename + "\", \"" + var.typedef + "\")"
        for prop in algorithm.properties:
            s += ",\n" \
              + ConfGen.prefix(i) + prop.name[1:-1] + "=Property" \
              + "(\"" + prop.typedef + "\", " \
              + "\"\", " + prop.description + ")"
        s += "):\n"
        s += ConfGen.prefix(i) + "self.__filename = \"" + algorithm.filename[len(
            AlgorithmParse().prefix_project_folder):] + "\"\n"
        s += ConfGen.prefix(i) + "self.__name = name\n"
        s += ConfGen.prefix(i) + "self.__original_name = \"" + algorithm.name + "\"\n"
        if algorithm.threetemplate:
            s += ConfGen.prefix(i) + "self.__requires_lines = True\n"
        else:
            s += ConfGen.prefix(i) + "self.__requires_lines = False\n"
        s += ConfGen.prefix(i) + "self.__namespace = \"" + algorithm.namespace + "\"\n"
        s += ConfGen.prefix(i) + "self.__ordered_parameters = OrderedDict(["
        i += 1
        for var in algorithm.parameters:
            s += "\n" + ConfGen.prefix(i) + "(\"" + var.typename + "\", " + ConfGen.create_var_type(var.kind) \
              + "(\"" + var.typename + "\", \"" + var.typedef + "\")),"
        s = s[:-1]
        if len(algorithm.parameters) > 0:
            s += "]"
        s += ")\n"
        i -= 1
        s += ConfGen.prefix(i) + "self.__ordered_properties = OrderedDict(["
        i += 1
        for prop in algorithm.properties:
            s += "\n" + ConfGen.prefix(i) + "(" + prop.name + ", Property" \
              + "(\"" + prop.typedef + "\", " \
              + "\"\", " + prop.description + ", " + prop.name[1:-1] + ")),"
        s = s[:-1]
        if len(algorithm.properties) > 0:
            s += "]"
        s += ")\n"
        i -= 1
        s += "\n"
        i -= 1

        s += ConfGen.prefix(i) + "def filename(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__filename\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def namespace(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__namespace\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def original_name(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__original_name\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def name(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__name\n\n"
        i -= 1

        s += ConfGen.prefix(i) + "def requires_lines(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__requires_lines\n\n"
        i -= 1

        for var in algorithm.parameters:
            s += ConfGen.prefix(i) + "def " + var.typename + "(self):\n"
            i += 1
            s += ConfGen.prefix(
                i) + "return self.__ordered_parameters[\"" + var.typename + "\"]\n\n"
            i -= 1

        for prop in algorithm.properties:
            s += ConfGen.prefix(i) + "def " + prop.name[1:-1] + "(self):\n"
            i += 1
            s += ConfGen.prefix(
                i) + "return self.__ordered_properties[" + prop.name + "]\n\n"
            i -= 1

        s += ConfGen.prefix(i) + "def parameters(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__ordered_parameters\n"
        i -= 1
        s += "\n"

        s += ConfGen.prefix(i) + "def properties(self):\n"
        i += 1
        s += ConfGen.prefix(i) + "return self.__ordered_properties\n"
        i -= 1
        s += "\n"

        s += ConfGen.prefix(i) + "def __repr__(self):\n"
        i += 1
        s += ConfGen.prefix(
            i
        ) + "s = self.__original_name + \" \\\"\" + self.__name + \"\\\" (\"\n"
        s += ConfGen.prefix(i) + "for k, v in iter(self.__ordered_parameters.items()):\n"
        i += 1
        s += ConfGen.prefix(i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
        i -= 1
        s += ConfGen.prefix(i) + "for k, v in iter(self.__ordered_properties.items()):\n"
        i += 1
        s += ConfGen.prefix(i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
        i -= 1
        s += ConfGen.prefix(i) + "s = s[:-2]\n"
        s += ConfGen.prefix(i) + "s += \")\"\n"
        s += ConfGen.prefix(i) + "return s\n"
        s += "\n\n"

        return s


if __name__ == '__main__':
    filename = "algorithms.py"
    
    print("Parsing algorithms...")
    parsed_algorithms = AlgorithmParse().parse_all()

    print("Generating " + filename + "...")
    s = ConfGen().write_preamble()
    for algorithm in parsed_algorithms:
        s += ConfGen().write_algorithm_code(algorithm)

    # for line in parsed_lines:
    #     s += write_line_code(line)

    f = open(filename, "w")
    f.write(s)
    f.close()

    print("File " + filename + " was successfully generated.")


# # Iterate all filenames in search for our pattern
# parsed_algorithms = []
# parsed_lines = []
# for filename in all_filenames:
#     f = open(filename)
#     s = f.read()
#     f.close()

#     line = line_pattern_compiled.search(s)
#     if line:
#         namespace = line_namespace_pattern_compiled.search(s)
#         if namespace:
#             parsed_lines.append(
#                 OrderedDict([("name", line.group("name")),
#                              ("line_type", line.group("line_type")),
#                              ("namespace", namespace.group("name")),
#                              ("filename", filename)]))

#     algorithm = algorithm_pattern_compiled.search(s)
#     if algorithm:
#         namespace = namespace_pattern_compiled.search(s)
#         if namespace:
#             variables = variable_pattern_compiled.finditer(s)
#             properties = property_pattern_compiled.finditer(s)

#             variable_map = OrderedDict([(v.group("name"),
#                                          OrderedDict(
#                                              [("scope", v.group("scope")),
#                                               ("io", v.group("io")),
#                                               ("type", v.group("type"))]))
#                                         for v in variables])

#             property_map = OrderedDict([
#                 (
#                     v.group("typename"),
#                     OrderedDict([
#                         ("name", v.group("name")),
#                         ("type", v.group("type")),
#                         ("default_value", ""),  # v.group("default_value")
#                         ("description", v.group("description"))
#                     ])) for v in properties
#             ])

#             parsed_algorithms.append(
#                 OrderedDict([("name", algorithm.group("name")),
#                              ("scope", algorithm.group("scope")),
#                              ("filename", filename),
#                              ("namespace", namespace.group("name")),
#                              ("threetemplate",
#                               algorithm.group("threetemplate")),
#                              ("variables", variable_map),
#                              ("properties", property_map)]))

# # print("Found", len(parsed_algorithms), "algorithms")
# # print(parsed_algorithms)

