###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from collections import OrderedDict
from PyConf.dataflow import GaudiDataHandle
from json import dump


def clean_prefix(s):
    """Transforms a type string from TES format into
    a string that can be used as a type identifier."""
    cleaned_s = s.replace("/Event/", "")
    cleaned_s = cleaned_s.replace("/", "__")
    cleaned_s = cleaned_s.replace("#", "_")
    return cleaned_s


def add_deps_and_transitive_deps(dep, arg_deps, parameter_dependencies_set):
    parameter_dependencies_set.add(dep)
    if dep in arg_deps:
        for transitive_dep in arg_deps[dep]:
            parameter_dependencies_set.add(transitive_dep)


def generate_json_configuration(algorithms, filename):
    """Generates runtime configuration (JSON)."""
    sequence_json = {}
    # Add properties for each algorithm
    for algorithm in algorithms:
        if len(algorithm.properties):
            sequence_json[algorithm.name] = {}
            for k, v in algorithm.properties.items():
                sequence_json[algorithm.name][str(k)] = v

    # Generate list of configured algorithms
    configured_algorithms = [[
        f"{algorithm.type.namespace()}::{algorithm.typename}", algorithm.name,
        algorithm.type.category()
    ] for algorithm in algorithms]

    # All output arguments
    configured_arguments = []
    for algorithm in algorithms:
        configured_arguments += [[
            algorithm.type.__slots__[a[0]].Scope,
            clean_prefix(a[1].location)
        ] for a in list(algorithm.outputs.items())]

    configured_sequence_arguments = []
    argument_dependencies = {}
    for algorithm in algorithms:
        arguments = []
        input_aggregates = []
        # Temporary map of parameter_name to parameter_full_name
        param_name_to_full_name = {}
        # Map of parameter_name to input_aggregates
        param_name_to_input_aggregates = {}

        gaudi_data_handles = [
            p for p in algorithm.type.getDefaultProperties().items()
            if isinstance(p[1], GaudiDataHandle)
        ]
        for (
                parameter_name,
                parameter,
        ) in gaudi_data_handles:
            # Deal with input aggregates separately
            if parameter_name in algorithm.inputs and type(
                    algorithm.inputs[parameter_name]) == list:
                input_aggregate = []
                for single_param_i, single_parameter in enumerate(
                        algorithm.inputs[parameter_name]):
                    parameter_full_name = clean_prefix(
                        single_parameter.location)
                    input_aggregate.append(f"{parameter_full_name}")
                input_aggregates.append(input_aggregate)
                param_name_to_input_aggregates[
                    parameter_name] = input_aggregate
            else:
                # It can be either an input or an output
                if parameter_name in algorithm.inputs:
                    parameter_location = algorithm.inputs[
                        parameter_name].location
                    parameter_full_name = clean_prefix(parameter_location)
                elif parameter_name in algorithm.outputs:
                    parameter_location = algorithm.outputs[
                        parameter_name].location
                    parameter_full_name = clean_prefix(parameter_location)
                    # If it is an output, check dependencies
                    dependencies = algorithm.type.__slots__[
                        parameter_name].Dependencies
                    if dependencies:
                        parameter_dependencies_set = set([])
                        for dep in dependencies:
                            # If it is an INPUT_AGGREGATE, deal with those dependencies
                            if dep in param_name_to_input_aggregates:
                                for dep_full_name in param_name_to_input_aggregates[
                                        dep]:
                                    add_deps_and_transitive_deps(
                                        dep_full_name, argument_dependencies,
                                        parameter_dependencies_set)
                            else:
                                dep_full_name = param_name_to_full_name[dep]
                                add_deps_and_transitive_deps(
                                    dep_full_name, argument_dependencies,
                                    parameter_dependencies_set)
                        argument_dependencies[parameter_full_name] = list(
                            parameter_dependencies_set)
                else:
                    raise "Parameter should either be an input or an output"
                arguments.append(parameter_full_name)
                param_name_to_full_name[parameter_name] = parameter_full_name
        configured_sequence_arguments.append([arguments, input_aggregates])

    sequence_json["sequence"] = {
        "configured_algorithms": configured_algorithms,
        "configured_arguments": configured_arguments,
        "configured_sequence_arguments": configured_sequence_arguments,
        "argument_dependencies": argument_dependencies
    }
    with open(filename, 'w') as outfile:
        dump(sequence_json, outfile, indent=4, sort_keys=True)


def generate_allen_sequence(algorithms,
                            json_configuration_filename="Sequence.json"):
    """Generates an Allen valid sequence.

    * json_configuration_filename: JSON configuration that can be changed at runtime to change
                                   values of properties.
    """
    generate_json_configuration(algorithms, json_configuration_filename)
