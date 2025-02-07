###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
import clang.cindex as cindex

event_list_alg_types = ("event_list_union_t", "event_list_inversion_t",
                        "event_list_intersection_t")


class ParsedAlgorithm():
    def __init__(self, name, scope, filename, namespace, parameters):
        self.name = name
        self.scope = scope
        self.filename = filename
        self.namespace = namespace
        self.parameters = parameters

        # Check parameters contains at most one input mask and one output mask
        input_masks = [
            a for a in parameters
            if "Input" in a.kind and a.typedef == "mask_t"
        ]
        output_masks = [
            a for a in parameters
            if "Output" in a.kind and a.typedef == "mask_t"
        ]
        if name not in event_list_alg_types:
            assert len(input_masks) <= 1,\
            f"Algorithm {self.name} does not fulfill condition: At most one input mask is allowed per algorithm."

        assert len(output_masks) <= 1,\
            f"Algorithm {self.name} does not fulfill condition: At most output mask is allowed per algorithm."

    def __repr__(self):
        return self.scope + " " + self.name


class Parameter():
    def __init__(self, typename, datatype, is_input, typedef, aggregate,
                 optional, dependencies):
        self.typename = typename
        self.typedef = typedef
        self.aggregate = aggregate
        self.optional = optional
        self.dependencies = dependencies
        if datatype == "Allen::Store::host_datatype":
            self.scope = "host"
            if is_input:
                self.kind = "HostInput"
            else:
                self.kind = "HostOutput"
        elif datatype == "Allen::Store::device_datatype":
            self.scope = "device"
            if is_input:
                self.kind = "DeviceInput"
            else:
                self.kind = "DeviceOutput"
        else:
            raise


def make_parsed_algorithms(filename, data):
    parsed_algorithms = []
    for namespace_data in data:
        if len(namespace_data) > 1 and len(namespace_data[2]) > 0:
            algorithm_data = namespace_data[2][0]
            # There is an algorithm defined here, fetch it
            namespace = namespace_data[1]
            name = algorithm_data[1]
            scope = algorithm_data[2]
            parameters = []
            for t in algorithm_data[3]:
                kind = t[0]
                if kind == "Parameter":
                    parameters.append(Parameter(*t[1:]))
            parsed_algorithms.append(
                ParsedAlgorithm(name, scope, filename, namespace, parameters))
    return parsed_algorithms


class AlgorithmTraversal():
    """Static class that traverses the code defining algorithms.
    This algorithm traversal operates on include files.
    The following syntax is required from an algorithm:

    namespace X {
        struct Y : public (HostAlgorithm|DeviceAlgorithm), Parameters {
            ...
        };
    }

    In addition, the Parameters class must be defined in the same header file."""

    # Accepted tokens for algorithm AllenConf
    __algorithm_tokens = [
        "HostAlgorithm", "DeviceAlgorithm", "SelectionAlgorithm",
        "ValidationAlgorithm", "ProviderAlgorithm", "BarrierAlgorithm"
    ]

    # Accepted tokens for parameter parsing
    __parameter_io_datatypes = [
        "Allen::Store::device_datatype", "Allen::Store::host_datatype"
    ]
    __parameter_aggregate = ["Allen::Store::aggregate_datatype"]
    __parameter_optional = ["Allen::Store::optional_datatype"]

    # Ignored namespaces. Definition of algorithms start by looking into namespaces,
    # therefore ignoring some speeds up the traversal.
    __ignored_namespaces = ["std", "__gnu_cxx", "__cxxabiv1", "__gnu_debug"]

    # Arguments to pass to compiler
    __compile_flags = ["-x", "c++", "-std=c++17", "-nostdinc++"]

    # Clang index
    __index = cindex.Index.create()

    # Properties and their default values
    __properties = {}

    @staticmethod
    def traverse_children(c, f, *args):
        """ Traverses the children of a cursor c by applying function f.
        Returns a list of traversed objects. If the result of traversing
        an object is None, it is ignored."""
        return_object = []
        for child_node in c.get_children():
            parsed_children = f(child_node, *args)
            if type(parsed_children) != type(None):
                return_object.append(parsed_children)
        return return_object

    @staticmethod
    def traverse_individual_parameters(c):
        """Traverses parameter c.

        For a parameter, we are searching for:
        * typename: Name of the class (ie. host_number_of_events_t).
        * kind: host / device.
        * io: input / output.
        * typedef: Type that it holds (ie. unsigned).
        """
        typename = c.spelling

        # Detect whether it is a parameter
        is_parameter = False
        for child in c.get_children():
            if child.kind == cindex.CursorKind.CXX_METHOD:
                if child.spelling == "parameter":
                    is_parameter = True
        # Parse parameters
        if is_parameter:
            # - Host / Device is now visible as a child class.
            # - There is a function (parameter) which captures:
            #   * f.is_const_method(): Input / Output
            #   * f.type.spelling: The type (restricted to POD types)
            kind = None
            io = None
            typedef = None
            aggregate = False
            optional = False
            dependencies = []
            for child in c.get_children():
                if child.kind == cindex.CursorKind.CXX_BASE_SPECIFIER and child.type.spelling in AlgorithmTraversal.__parameter_io_datatypes:
                    kind = child.type.spelling
                elif child.kind == cindex.CursorKind.CXX_BASE_SPECIFIER and child.type.spelling in AlgorithmTraversal.__parameter_aggregate:
                    aggregate = True
                elif child.kind == cindex.CursorKind.CXX_BASE_SPECIFIER and child.type.spelling in AlgorithmTraversal.__parameter_optional:
                    optional = True
                elif child.kind == cindex.CursorKind.CXX_METHOD:
                    io = child.is_const_method()
                    typedef = [
                        a.type.get_canonical().spelling
                        for a in child.get_children()
                    ][0]
                    for i in range(
                            child.result_type.get_num_template_arguments()):
                        dependencies.append(
                            child.result_type.get_template_argument_type(i).
                            get_canonical().spelling)
            if typedef == "" or typedef == "int" or aggregate:
                # This happens if the type cannot be parsed
                typedef = "unknown_t"
            if kind and typedef and io != None:
                return ("Parameter", typename, kind, io, typedef, aggregate,
                        optional, dependencies)
        return None

    @staticmethod
    def parameters(c):
        """Traverses all parameters of an Algorithm."""
        if c.kind == cindex.CursorKind.STRUCT_DECL:
            return AlgorithmTraversal.traverse_individual_parameters(c)
        else:
            return None

    @staticmethod
    def algorithm_definition(c):
        """Traverses an algorithm definition. If a base class other than __algorithm_tokens
        is found, it delegates traversing the parameters."""
        if c.kind == cindex.CursorKind.CXX_BASE_SPECIFIER:
            if c.type.spelling in AlgorithmTraversal.__algorithm_tokens:
                return ("AlgorithmClass", c.kind, c.type.spelling)
            elif "Parameters" in c.type.spelling:
                return AlgorithmTraversal.traverse_children(
                    c.get_definition(), AlgorithmTraversal.parameters)
        else:
            return None

    @staticmethod
    def algorithm(c):
        """Traverses an algorithm. First, it identifies whether the struct has
        an Algorithm token among its tokens (eg. "HostAlgorithm", "DeviceAlgorithm", etc.). If so,
        it proceeds to find algorithm parameters, template parameters, and returns a quintuplet:
        (kind, spelling, algorithm class, algorithm parameters)."""
        if c.kind in [
                cindex.CursorKind.STRUCT_DECL, cindex.CursorKind.CLASS_DECL
        ]:
            # Fetch the class and parameters of the algorithm
            algorithm_class = ""
            algorithm_parameters = []
            algorithm_class_parameters = AlgorithmTraversal.traverse_children(
                c, AlgorithmTraversal.algorithm_definition)
            # Add properties
            for _, prop in AlgorithmTraversal.__properties.items():
                algorithm_class_parameters.append(
                    ("Property", prop["name"], prop["variable_type"],
                     prop["description"], prop["default_value"]))
            algorithm_properties = []

            for d in algorithm_class_parameters:
                if d[0] == "AlgorithmClass":
                    algorithm_class = d[2]
                elif d[0] == "Property":
                    algorithm_properties.append(d)
                elif type(d) == list:
                    algorithm_parameters = d
            parameters_and_properties = algorithm_parameters + algorithm_properties
            if algorithm_class != "":
                return (c.kind, c.spelling, algorithm_class,
                        parameters_and_properties)
            else:
                return None
        else:
            return None

    @staticmethod
    def namespace(c, filename):
        """Traverses the namespaces.

        As there is no other way to obtain literals
        (eg. https://stackoverflow.com/questions/25520945/how-to-retrieve-function-call-argument-values-using-libclang),
        the list of tokens needs to be parsed to find the default names and descriptions of properties.
        """
        if c.kind == cindex.CursorKind.NAMESPACE and c.spelling not in AlgorithmTraversal.__ignored_namespaces and \
            c.location.file.name == filename:
            ts = [a.spelling for a in c.get_tokens()]
            # Check if it is a "new algorithm", which is identified by locating
            # at least one of the tokens in AlgorithmTraversal.__algorithm_tokens:
            if [a for a in AlgorithmTraversal.__algorithm_tokens if a in ts]:
                properties = {}
                last_found = -1
                while True:
                    # Loop over all "Property"s until there are no more to be parsed
                    try:
                        last_found = ts.index("Property", last_found + 1)
                    except ValueError:
                        break
                    # Traverse the "Property"s to find out the default values
                    pass
                    this_position = ts.index("this", last_found)
                    semicolon_position = ts.index(";", last_found)
                    variable_type = " ".join(
                        ts[last_found + 2:this_position - 2])[:-1]
                    variable_name = ts[this_position - 2]
                    name = ts[this_position + 2]
                    description = ts[semicolon_position - 2]
                    default_value = "".join(
                        ts[this_position + 4:semicolon_position - 3])
                    properties[variable_name] = {
                        "name": name,
                        "description": description,
                        "variable_type": variable_type,
                        "default_value": default_value
                    }

                AlgorithmTraversal.__properties = properties

                return (c.kind, c.spelling,
                        AlgorithmTraversal.traverse_children(
                            c, AlgorithmTraversal.algorithm))
        return None

    @staticmethod
    def traverse(filename, project_location="../"):
        """Opens the file with libClang, parses it and find algorithms.
        Returns a list of ParsedAlgorithms."""
        AlgorithmTraversal.__properties = {}
        clang_args = AlgorithmTraversal.__compile_flags.copy()
        clang_args.append("-I" + project_location + "/stream/gear/include")
        clang_args.append("-I" + project_location + "/stream/store/include")
        clang_args.append("-I" + project_location + "/backend/include")
        tu = AlgorithmTraversal.__index.parse(filename, args=clang_args)
        if tu.cursor.kind == cindex.CursorKind.TRANSLATION_UNIT:
            return make_parsed_algorithms(
                filename,
                AlgorithmTraversal.traverse_children(
                    tu.cursor, AlgorithmTraversal.namespace, filename))
        else:
            return None
