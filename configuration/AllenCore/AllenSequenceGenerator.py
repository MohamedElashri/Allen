###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from collections import OrderedDict
from PyConf.dataflow import GaudiDataHandle
from AllenConf.algorithms import AlgorithmCategory
from json import dump


def clean_prefix(s):
    """Transforms a type string from TES format into
    a string that can be used as a type identifier."""
    cleaned_s = s.replace("/Event/", "")
    cleaned_s = cleaned_s.replace("/", "__")
    cleaned_s = cleaned_s.replace("#", "_")
    return cleaned_s


def generate_sequence(algorithms, sequence_filename, prefix_includes):
    """Generates a valid Allen sequence file."""

    # Generate the includes with all algorithm headers
    s = "#pragma once\n\n#include <tuple>\n"
    set_of_includes = set(
        [algorithm.type.filename() for algorithm in algorithms])
    for include in set_of_includes:
        s += '#include "' + prefix_includes + include + '"\n'
    s += "\n"

    # Fetch all parameters from all algorithms
    parameters = OrderedDict([])
    for algorithm in algorithms:
        # All parameters
        all_parameters = [
            (a[0], a[1], "input") for a in list(algorithm.inputs.items())
        ] + [(a[0], a[1], "output")
             for a in list(algorithm.outputs.items())]

        for parameter_name, parameter_dh, io in all_parameters:
            if type(parameter_dh) != list:
                parameter_full_name = clean_prefix(
                    parameter_dh.location)
                # Verify that inputs are already populated
                assert (io != "input" or parameter_full_name in parameters
                        ), "Inputs should be provided by some output"
                param_data = (algorithm.name, algorithm.type.namespace(),
                              parameter_name, algorithm.type.filename())

                if io == "output":
                    parameters[parameter_full_name] = [param_data]
                else:
                    parameters[parameter_full_name].append(param_data)
            else:
                # Input aggregates
                assert (io == "input"), "Aggregates can only be inputs"
                for single_parameter in parameter_dh:
                    parameter_full_name = clean_prefix(
                        single_parameter.location)
                    assert (parameter_full_name in parameters
                            ), "Inputs should be provided by some output"

    # Generate parameters with inheriting classes that are not in aggregates
    for parameter_full_name, v in iter(parameters.items()):
        s += "struct " + parameter_full_name + " : "
        inheriting_classes = []
        for algorithm_name, algorithm_namespace, parameter_name, _ in v:
            parameter = f"{algorithm_namespace}::Parameters::{parameter_name}"
            if parameter not in inheriting_classes:
                inheriting_classes.append(parameter)
        for i, inheriting_class in enumerate(inheriting_classes):
            s += inheriting_class
            if i != len(inheriting_classes) - 1:
                s += ", "
        _, first_parameter_namespace, first_parameter_name, _ = v[0]
        s += (
            f" {{ using type = {first_parameter_namespace}::Parameters::{first_parameter_name}::type;"
            f" using deps = {first_parameter_namespace}::Parameters::{first_parameter_name}::deps; }};\n"
        )

    # Generate static_asserts for all generated parameters, checking they all inherit
    # from either host_datatype or device_datatype
    s += "\n"
    for parameter_full_name, v in iter(parameters.items()):
        s += f"static_assert(all_host_or_all_device_v<{parameter_full_name}"
        for algorithm_name, algorithm_namespace, parameter_name, _ in v:
            s += f", {algorithm_namespace}::Parameters::{parameter_name}"
        s += ">);\n"

    # Generate a list of configured arguments
    s += "\nusing configured_arguments_t = std::tuple<\n"
    for i, (parameter_full_name, _) in enumerate(parameters.items()):
        s += f"  {parameter_full_name}"
        if i != len(parameters) - 1:
            s += ",\n"
        else:
            s += ">;\n"

    # Generate a list of configured algorithms
    s += "\nusing configured_sequence_t = std::tuple<\n"
    for i, algorithm in enumerate(algorithms):
        s += f"  {algorithm.type.namespace()}::{algorithm.type.getType()}"
        if i != len(algorithms) - 1:
            s += ",\n"
        else:
            s += ">;\n"

    # Generate a list of configured arguments for each algorithm
    s += "\nusing configured_sequence_arguments_t = std::tuple<\n"
    for i, algorithm in enumerate(algorithms):
        s += "  std::tuple<"
        for (
                parameter_name,
                parameter,
        ) in algorithm.type.getDefaultProperties().items():
            if isinstance(parameter, GaudiDataHandle):
                # Deal with input aggregates separately
                if parameter_name in algorithm.inputs and type(
                        algorithm.inputs[parameter_name]) == list:
                    s += "std::tuple<"
                    for single_parameter in algorithm.inputs[
                            parameter_name]:
                        parameter_full_name = clean_prefix(
                            single_parameter.location)
                        s += f"{parameter_full_name}, "
                    s = s[:-2] + ">, "
                else:
                    # It can be either an input or an output
                    if parameter_name in algorithm.inputs:
                        parameter_location = algorithm.inputs[
                            parameter_name].location
                    elif parameter_name in algorithm.outputs:
                        parameter_location = algorithm.outputs[
                            parameter_name].location
                    else:
                        raise "Parameter should either be an input or an output"
                    parameter_full_name = clean_prefix(
                        parameter_location)
                    s += f"{parameter_full_name}, "
        s = s[:-2] + ">"
        if i != len(algorithms) - 1:
            s += ",\n"
        else:
            s += ">;\n\n"

    # Generate get_sequence_algorithm_names function
    s += "constexpr auto sequence_algorithm_names = std::array{\n"
    for i, algorithm in enumerate(algorithms):
        s += f"  \"{algorithm.name}\""
        if i != len(algorithms) - 1: s += ",\n"
    s += "};\n\n"

    # Generate populate_sequence_parameter_names
    s += "template<typename T>\nvoid populate_sequence_argument_names(T& argument_manager) {\n"
    for parameter_name in iter(parameters.keys()):
        s += f"  argument_manager.template set_name<{parameter_name}>(\"{parameter_name}\");\n"
    s += "}\n"
    with open(sequence_filename, "w") as f:
        f.write(s)


def generate_json_configuration(algorithms, filename):
    """Generates runtime configuration (JSON)."""
    sequence_json = {}
    # Add properties for each algorithm
    for algorithm in algorithms:
        if len(algorithm.properties):
            sequence_json[algorithm.name] = {}
            for k, v in algorithm.properties.items():
                sequence_json[algorithm.name][str(k)] = str(v)
    # Add configured lines
    configured_lines = []
    for algorithm in algorithms:
        if algorithm.type.category(
        ) == AlgorithmCategory.SelectionAlgorithm:
            configured_lines.append(algorithm.name)
    sequence_json["configured_lines"] = configured_lines
    with open(filename, 'w') as outfile:
        dump(sequence_json, outfile)
        

def generate_allen_sequence(
    algorithms,
    sequence_filename="Sequence.h",
    json_configuration_filename="Sequence.json",
    prefix_includes=""
):
    """Generates an Allen valid sequence.

    This function expects configured algorithms and generates three output files,
    which will be used to build a specific Allen sequence:

    * sequence_filename: Sequence file containing arguments used in the memory manager,
                         initialization of those arguments, a setter function to set their names,
                         the algorithms to be executed and instantiations of those algorithms with arguments.
    * json_configuration_filename: JSON configuration that can be changed at runtime to change
                                   values of properties.
    """
    print("Generating sequence files...")

    generate_sequence(algorithms, sequence_filename, prefix_includes)

    generate_json_configuration(algorithms, json_configuration_filename)
    
    print(
        f"Generated sequence files {sequence_filename} and {json_configuration_filename}"
    )
