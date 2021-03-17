###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from collections import OrderedDict
from PyConf.dataflow import GaudiDataHandle
from definitions.algorithms import algorithms_with_aggregates, AlgorithmCategory
from json import dump


def clean_prefix(s):
    """Transforms a type string from TES format into
    a string that can be used as a type identifier."""
    cleaned_s = s.replace("/Event/", "")
    cleaned_s = cleaned_s.replace("/", "__")
    cleaned_s = cleaned_s.replace("#", "_")
    return cleaned_s


def generate_sequence(algorithms, sequence_filename, input_aggregates_filename, prefix_includes):
    """Generates a valid Allen sequence file."""

    # Generate the includes with all algorithm headers
    s = "#pragma once\n\n#include <tuple>\n"
    s += "#include \"" + input_aggregates_filename + "\"\n"
    set_of_includes = set(
        [algorithm.type.filename() for algorithm in algorithms])
    for include in set_of_includes:
        s += '#include "' + prefix_includes + include + '"\n'
    s += "\n"

    # Fetch all parameters from all algorithms
    parameters = OrderedDict([])
    parameters_part_of_aggregates = []
    input_aggregates_parameter_full_names = OrderedDict([])
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
                if algorithm not in input_aggregates_parameter_full_names:
                    input_aggregates_parameter_full_names[algorithm] = {}
                if parameter_name not in input_aggregates_parameter_full_names[
                        algorithm]:
                    input_aggregates_parameter_full_names[algorithm][
                        parameter_name] = []
                for single_parameter in parameter_dh:
                    parameter_full_name = clean_prefix(
                        single_parameter.location)
                    assert (parameter_full_name in parameters
                            ), "Inputs should be provided by some output"
                    parameters_part_of_aggregates.append(
                        parameter_full_name)
                    input_aggregates_parameter_full_names[algorithm][
                        parameter_name].append(parameter_full_name)

    # Generate parameters with inheriting classes that are not in aggregates
    for parameter_full_name, v in iter(parameters.items()):
        if parameter_full_name not in parameters_part_of_aggregates:
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
                f" {{ using type = {first_parameter_namespace}::Parameters::{first_parameter_name}::type; }};\n"
            )

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
                    for single_parameter in algorithm.inputs[
                            parameter_name]:
                        parameter_full_name = clean_prefix(
                            single_parameter.location)
                        s += f"{parameter_full_name}, "
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
            s += ">;\n"

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

    return parameters, parameters_part_of_aggregates, input_aggregates_parameter_full_names


def generate_input_aggregates(
        algorithms,
        input_aggregates_filename,
        prefix_includes,
        parameters,
        parameters_part_of_aggregates,
        input_aggregates_parameter_full_names
):
    """Generates an input aggregates configuration file."""

    # Generate input aggregates file
    s = "#pragma once\n\n#include <tuple>\n"
    algorithms_with_aggregates_list = algorithms_with_aggregates()
    parameter_producers = set()
    # Generate includes of filenames
    filenames = set()
    for parameter_full_name in parameters_part_of_aggregates:
        for _, _, _, algorithm_filename in parameters[parameter_full_name]:
            filenames.add(algorithm_filename)
    for filename in filenames:
        s += "#include \"" + prefix_includes + filename + "\"\n"
    s += "\n"
    # Generate typenames that participate in aggregates
    for parameter_full_name in parameters_part_of_aggregates:
        v = parameters[parameter_full_name]
        s += "struct " + parameter_full_name + " : "
        inheriting_classes = []
        for _, algorithm_namespace, parameter_full_name, _ in v:
            parameter = f"{algorithm_namespace}::Parameters::{parameter_full_name}"
            if parameter not in inheriting_classes:
                inheriting_classes.append(parameter)
        for inheriting_class in inheriting_classes:
            s += inheriting_class + ", "
        s = s[:-2]
        s += " { using type = " + v[0][1] + "::Parameters::" + v[0][
            2] + "::type; };\n"

    s += "\n"
    for algorithm_with_aggregate_class in algorithms_with_aggregates_list:
        instance_of_alg_class = [
            alg for alg in algorithms
            if alg.type == algorithm_with_aggregate_class
        ]
        if len(instance_of_alg_class):
            for algorithm in instance_of_alg_class:
                for parameter_name, parameter_full_names in input_aggregates_parameter_full_names[
                        algorithm].items():
                    s += "namespace " + algorithm_with_aggregate_class.namespace(
                    ) + " { namespace " + parameter_name + " { using tuple_t = std::tuple<"
                    for i, p in enumerate(parameter_full_names):
                        s += p
                        if i != len(parameter_full_names) - 1:
                            s += ", "
                    s += ">; }}\n"
        else:
            # Since there are no instances of that algorithm,
            # at least we need to populate the aggregate inputs as empty
            for parameter_name in algorithm_with_aggregate_class.aggregates:
                s += "namespace " + algorithm_with_aggregate_class.namespace(
                ) + " { namespace " + parameter_name + " { using tuple_t = std::tuple<>; }}\n"
    with open(input_aggregates_filename, "w") as f:
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
    input_aggregates_filename="ConfiguredInputAggregates.h",
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
    * input_aggregates_filename: Additional sequence file containing the configured input aggregates in
                                 configured algorithms that require them.
    """
    print("Generating sequence files...")

    parameters, parameters_part_of_aggregates, input_aggregates_parameter_full_names =
        generate_sequence(algorithms, sequence_filename, input_aggregates_filename, prefix_includes)
    generate_input_aggregates(algorithms, input_aggregates_filename, prefix_includes, parameters, parameters_part_of_aggregates, input_aggregates_parameter_full_names)
    generate_json_configuration(algorithms, json_configuration_filename)
    
    print(
        f"Generated sequence files {sequence_filename}, {input_aggregates_filename} and {json_configuration_filename}"
    )
