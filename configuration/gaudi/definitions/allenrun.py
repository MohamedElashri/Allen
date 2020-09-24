#!/usr/bin/python2
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

from __future__ import print_function
from collections import OrderedDict
from sys import argv

optsfile = argv[1]
exec (open(optsfile).read())

from AllenKernel import AllenAlgorithm

algs = AllenAlgorithm._all_algs


class Sequence():
    """Helper class to generate an Allen compatible sequence."""

    @classmethod
    def clean_prefix(cls, s):
        cleaned_s = ""
        try:
            index_prefix = s.index("/Event/")
            cleaned_s = s[7:]
        except:
            try:
                index_prefix = s.index("/")
                cleaned_s = s[1:]
            except:
                cleaned_s = s
        cleaned_s = cleaned_s.replace("/", "__")
        return cleaned_s

    @classmethod
    def generate(cls,
                 algorithms,
                 output_filename="Sequence.h",
                 json_configuration_filename="Sequence.json",
                 prefix_includes="../../"):

        print("Generating sequence file...")

        # Add all the includes
        s = "#pragma once\n\n#include <tuple>\n"
        s += "#include \"" + prefix_includes + "cuda/selections/Hlt1/include/LineTraverser.cuh\"\n"
        for _, algorithm in iter(algorithms.items()):
            s += "#include \"" + prefix_includes + algorithm.filename(
            ) + "\"\n"
        s += "\n"

        # Generate all parameters
        parameters = OrderedDict([])
        for _, algorithm in iter(algorithms.items()):
            for parameter_name, _ in iter(algorithm.__slots__.items()):
                parameter_t = Sequence.clean_prefix(
                    getattr(algorithm, parameter_name))
                algorithm_name = algorithm.getType()
                algorithm_namespace = algorithm.namespace()
                if parameter_t in parameters:
                    parameters[parameter_t].append(
                        (algorithm_name, algorithm_namespace, parameter_name))
                else:
                    parameters[parameter_t] = [(algorithm_name,
                                                algorithm_namespace,
                                                parameter_name)]

        # Generate configuration
        for paramenter_name, v in iter(parameters.items()):
            s += "struct " + paramenter_name + " : "
            inheriting_classes = []
            for algorithm_name, algorithm_namespace, parameter_t in v:
                parameter = algorithm_namespace + "::Parameters::" + parameter_t
                if parameter not in inheriting_classes:
                    inheriting_classes.append(parameter)
            for inheriting_class in inheriting_classes:
                s += inheriting_class + ", "
            s = s[:-2]
            s += " { constexpr static auto name {\"" + paramenter_name + "\"}; size_t size; char* offset; };\n"

        # Generate empty lines
        s += "\nusing configured_lines_t = std::tuple<>;\n"

        # Generate sequence
        s += "\nusing configured_sequence_t = std::tuple<\n"
        i_alg = 0
        for algorithm_name, algorithm in iter(algorithms.items()):
            i_alg += 1
            # Add algorithm namespace::name
            s += "  " + algorithm.namespace() + "::" + algorithm.getType(
            ) + "<std::tuple<"
            i = 0
            # Add parameters
            for parameter_name, _ in iter(algorithm.__slots__.items()):
                parameter_t = Sequence.clean_prefix(
                    getattr(algorithm, parameter_name))
                i += 1
                s += parameter_t
                if i != len(algorithm.__slots__):
                    s += ", "
            s += ">, "
            i = 0
            # Add name
            for c in algorithm_name:
                i += 1
                s += "'" + c + "'"
                if i != len(algorithm_name):
                    s += ", "
            s += ">"
            if i_alg != len(algorithms.items()):
                s += ","
            s += "\n"
        s += ">;\n"

        f = open(output_filename, "w")
        f.write(s)
        f.close()

        print("Generated sequence file " + output_filename)
        print("Generating JSON configuration file...")
        s = "{}\n"
        f = open(json_configuration_filename, "w")
        f.write(s)
        f.close()
        print("Generated JSON configuration file " +
              json_configuration_filename)


# Generate sequence
Sequence().generate(algs)
