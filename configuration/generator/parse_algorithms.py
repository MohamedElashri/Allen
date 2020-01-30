#!/usr/bin/python3

import re
import os
from collections import OrderedDict

def get_filenames(folder, extensions):
  list_of_files = []
  for root, subdirs, files in os.walk(folder):
    # for subdir in subdirs:
    #   list_of_files += get_filenames(os.path.join(folder, subdir), extensions)
    for filename in files:
      for extension in extensions:
        if extension.match(filename):
          list_of_files.append(os.path.join(root, filename))
          break
  return list_of_files

algorithm_pattern = "template<typename T,[ ]*(?P<threetemplate>typename U,[ ]*)?char... S>.*?struct (?P<name>[\\w_]+) : public (?P<scope>Host|Device)Algorithm"
variable_pattern = "(?P<scope>HOST|DEVICE)_(?P<io>INPUT|OUTPUT)\\((?P<name>[\\w_]+), (?P<type>[^)]+)\\)" # ( [\\w_]+)?;
namespace_pattern = "namespace (?P<name>[\\w_]+).*?public (?P<scope>Host|Device)Algorithm"
property_pattern = "PROPERTY\\(.*?(?P<typename>[\\w_]+),.*?(?P<type>[^,]+),.*?(?P<name>[^,]+),.*?(?P<description>[^,]+),.*?(?P<default_value>[^\\)]+)\\)" # ( [\\w_]+)?;
line_pattern = "struct (?P<name>[\\w_]+) : public Hlt1::(?P<line_type>[\\w_]+)Line"
line_namespace_pattern = "namespace (?P<name>[\\w_]+)"

algorithm_pattern_compiled = re.compile(algorithm_pattern, re.DOTALL)
variable_pattern_compiled = re.compile(variable_pattern)
namespace_pattern_compiled = re.compile(namespace_pattern, re.DOTALL)
property_pattern_compiled = re.compile(property_pattern, re.DOTALL)
line_pattern_compiled = re.compile(line_pattern, re.DOTALL)
line_namespace_pattern_compiled = re.compile(line_namespace_pattern, re.DOTALL)

prefix_project_folder = "../../"
device_folder = prefix_project_folder + "cuda"
host_folder = prefix_project_folder + "x86"
sought_extensions = ["cuh", "h", "hpp"]
sought_extensions_compiled = [re.compile(".*\\." + p + "$") for p in sought_extensions]

all_filenames = get_filenames(device_folder, sought_extensions_compiled) + get_filenames(host_folder, sought_extensions_compiled)

# Iterate all filenames in search for our pattern
parsed_algorithms = []
parsed_lines = []
for filename in all_filenames:
  f = open(filename)
  s = f.read()
  f.close()

  line = line_pattern_compiled.search(s)
  if line:
    namespace = line_namespace_pattern_compiled.search(s)
    if namespace:
      parsed_lines.append(OrderedDict([
        ("name", line.group("name")),
        ("line_type", line.group("line_type")),
        ("namespace", namespace.group("name")),
        ("filename", filename)
        ]))

  algorithm = algorithm_pattern_compiled.search(s)
  if algorithm:
    namespace = namespace_pattern_compiled.search(s)
    if namespace:
      variables = variable_pattern_compiled.finditer(s)
      properties = property_pattern_compiled.finditer(s)

      variable_map = OrderedDict([(v.group("name"), OrderedDict([
        ("scope", v.group("scope")),
        ("io", v.group("io")),
        ("type", v.group("type"))
        ])) for v in variables])

      property_map = OrderedDict([(v.group("typename"), OrderedDict([
        ("name", v.group("name")),
        ("type", v.group("type")),
        ("default_value", v.group("default_value")),
        ("description", v.group("description"))
        ])) for v in properties])


      parsed_algorithms.append(OrderedDict([
        ("name", algorithm.group("name")),
        ("scope", algorithm.group("scope")),
        ("filename", filename),
        ("namespace", namespace.group("name")),
        ("threetemplate", algorithm.group("threetemplate")),
        ("variables", variable_map),
        ("properties", property_map)
        ]))

# print("Found", len(parsed_algorithms), "algorithms")
# print(parsed_algorithms)

def prefix(indentation_level, indent_by = 2):
  return "".join([" "] * indentation_level * indent_by)


def create_var_type(scope, io):
  t = ""
  if scope == "DEVICE":
    t = "Device"
  elif scope == "HOST":
    t = "Host"
  if io == "INPUT":
    t += "Input"
  elif io == "OUTPUT":
    t += "Output"
  return t


def write_preamble(i = 0):
  s = "from collections import OrderedDict\nfrom base_types import *\n\n"
  return s


def write_line_code(line, i = 0):
  s = prefix(i) + "class " + line["name"] + "(" + line["line_type"] + "Line):\n"
  i += 1
  s += prefix(i) + "def __init__(self):\n"
  i += 1
  s += prefix(i) + "self.__name=\"" + line["name"] + "\"\n"
  s += prefix(i) + "self.__filename=\"" + line["filename"][len(prefix_project_folder):] + "\"\n"
  s += prefix(i) + "self.__namespace=\"" + line["namespace"] + "\"\n"
  i -= 1
  s += "\n"

  s += prefix(i) + "def filename(self):\n"
  i += 1
  s += prefix(i) + "return self.__filename\n\n"
  i -= 1

  s += prefix(i) + "def namespace(self):\n"
  i += 1
  s += prefix(i) + "return self.__namespace\n\n"
  i -= 1

  s += prefix(i) + "def name(self):\n"
  i += 1
  s += prefix(i) + "return self.__name\n\n"
  i -= 2
  s += "\n"

  return s


def write_algorithm_code(algorithm, i = 0):
  s = prefix(i) + "class " + algorithm["name"] + "(" + algorithm["scope"] + "Algorithm):\n"
  i += 1
  s += prefix(i) + "def __init__(self,\n"
  i += 1
  s += prefix(i) + "name=\"" + algorithm["name"] + "\""
  for var_name, var in iter(algorithm["variables"].items()):
    s += ",\n" \
      + prefix(i) + var_name + "=" + create_var_type(var["scope"], var["io"]) \
      + "(\"" + var_name + "\", \"" + var["type"] + "\")"
  for prop_name, prop in iter(algorithm["properties"].items()):
    s += ",\n" \
      + prefix(i) + prop_name + "= Property" \
      + "(\"" + prop["type"].strip() + "\", " \
      + "\"" + prop["default_value"].strip() + "\", " + prop["description"].strip() + ")"
  s += "):\n"
  s += prefix(i) + "self.__filename = \"" + algorithm["filename"][len(prefix_project_folder):] + "\"\n"
  s += prefix(i) + "self.__name = name\n"
  s += prefix(i) + "self.__original_name = \"" + algorithm["name"] + "\"\n"
  if algorithm["threetemplate"] == None:
    s += prefix(i) + "self.__requires_lines = False\n"
  else:
    s += prefix(i) + "self.__requires_lines = True\n"
  s += prefix(i) + "self.__namespace = \"" + algorithm["namespace"] + "\"\n"
  s += prefix(i) + "self.__ordered_parameters = OrderedDict(["
  i += 1
  for var_name, var in iter(algorithm["variables"].items()):
    s += "\n" + prefix(i) + "(\"" + var_name + "\", " + create_var_type(var["scope"], var["io"]) \
      + "(" + var_name + ", \"" + var["type"] + "\")),"
  s = s[:-1]
  if len(algorithm["variables"]) > 0:
    s += "]"
  s += ")\n"
  i -= 1
  s += prefix(i) + "self.__ordered_properties = OrderedDict(["
  i += 1
  for prop_name, prop in iter(algorithm["properties"].items()):
    s += "\n" + prefix(i) + "(" + prop["name"].strip() + ", Property" \
      + "(\"" + prop["type"].strip() + "\", " \
      + "\"" + prop["default_value"].strip() + "\", " + prop["description"].strip() + ", " + prop_name + ")),"
  s = s[:-1]
  if len(algorithm["properties"]) > 0:
    s += "]"
  s += ")\n"
  i -= 1
  s += "\n"
  i -= 1

  s += prefix(i) + "def filename(self):\n"
  i += 1
  s += prefix(i) + "return self.__filename\n\n"
  i -= 1

  s += prefix(i) + "def namespace(self):\n"
  i += 1
  s += prefix(i) + "return self.__namespace\n\n"
  i -= 1

  s += prefix(i) + "def original_name(self):\n"
  i += 1
  s += prefix(i) + "return self.__original_name\n\n"
  i -= 1

  s += prefix(i) + "def name(self):\n"
  i += 1
  s += prefix(i) + "return self.__name\n\n"
  i -= 1

  s += prefix(i) + "def requires_lines(self):\n"
  i += 1
  s += prefix(i) + "return self.__requires_lines\n\n"
  i -= 1

  for var_name, var in iter(algorithm["variables"].items()):
    s += prefix(i) + "def " + var_name + "(self):\n"
    i += 1
    s += prefix(i) + "return self.__ordered_parameters[\"" + var_name + "\"]\n\n"
    i -= 1

  for prop_name, prop in iter(algorithm["properties"].items()):
    s += prefix(i) + "def property_" + prop_name + "(self):\n"
    i += 1
    s += prefix(i) + "return self.__ordered_properties[\"" + prop_name + "\"]\n\n"
    i -= 1

  s += prefix(i) + "def parameters(self):\n"
  i += 1
  s += prefix(i) + "return self.__ordered_parameters\n"
  i -= 1
  s += "\n"

  s += prefix(i) + "def properties(self):\n"
  i += 1
  s += prefix(i) + "return self.__ordered_properties\n"
  i -= 1
  s += "\n"

  s += prefix(i) + "def __repr__(self):\n"
  i += 1
  s += prefix(i) + "s = self.__original_name + \" \\\"\" + self.__name + \"\\\" (\"\n"
  s += prefix(i) + "for k, v in iter(self.__ordered_parameters.items()):\n"
  i += 1
  s += prefix(i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
  i -= 1
  s += prefix(i) + "for k, v in iter(self.__ordered_properties.items()):\n"
  i += 1
  s += prefix(i) + "s += \"\\n  \" + k + \" = \" + repr(v) + \", \"\n"
  i -= 1
  s += prefix(i) + "s = s[:-2]\n"
  s += prefix(i) + "s += \")\"\n"
  s += prefix(i) + "return s\n"
  s += "\n\n"

  return s


if __name__ == '__main__':
  filename = "algorithms.py"
  print("Generating " + filename + "...")

  s = write_preamble()
  for algorithm in parsed_algorithms:
    s += write_algorithm_code(algorithm)

  for line in parsed_lines:
    s += write_line_code(line)

  f = open(filename, "w")
  f.write(s)
  f.close()

  print("File " + filename + " was successfully generated.")
