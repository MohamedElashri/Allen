###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import clang.cindex as cindex

event_list_alg_types = ("event_list_union_t", "event_list_inversion_t",
                        "event_list_intersection_t")


class ParsedAlgorithm():
    def __init__(self, name, scope, filename, namespace, parameters,
                 properties):
        self.name = name
        self.scope = scope
        self.filename = filename
        self.namespace = namespace
        self.parameters = parameters
        self.properties = properties

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

        # Check maximum number of parameters does not exceed 40
        assert len(parameters) <= 40,\
            f"Algorithm {self.name} does not fulfill condition: At most 40 parameters may be defined per algorithm."

    def __repr__(self):
        return self.scope + " " + self.name


class Property():
    def __init__(self, typename, typedef, name, description, default_value, scope = "algorithm"):
        self.typename = typename
        self.typedef = typedef
        self.name = name
        self.description = description
        self.default_value = default_value
        self.scope = scope


class Parameter():
    def __init__(self, typename, datatype, is_input, typedef, aggregate, optional, dependencies):
        self.typename = typename
        self.typedef = typedef
        self.aggregate = aggregate
        self.optional = optional
        self.dependencies = dependencies
        if datatype == "host_datatype":
            self.scope = "host"
            if is_input:
                self.kind = "HostInput"
            else:
                self.kind = "HostOutput"
        elif datatype == "device_datatype":
            self.scope = "device"
            if is_input:
                self.kind = "DeviceInput"
            else:
                self.kind = "DeviceOutput"
        else:
            raise


# TODO: Parse these from Algorithm.cuh
def make_default_algorithm_properties():
    return [
        Property("verbosity_t", "int", "\"verbosity\"",
                 "\"verbosity of algorithm\"", 3, "baseclass")
    ]


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
            properties = []
            # Add default properties
            for default_property in make_default_algorithm_properties():
                properties.append(default_property)
            for t in algorithm_data[3]:
                kind = t[0]
                if kind == "Property":
                    properties.append(Property(*t[1:]))
                elif kind == "Parameter":
                    parameters.append(Parameter(*t[1:]))
            parsed_algorithms.append(
                ParsedAlgorithm(name, scope, filename, namespace, parameters,
                                properties))
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
        "ValidationAlgorithm"
    ]

    # Accepted tokens for parameter parsing
    __parameter_io_datatypes = ["device_datatype", "host_datatype"]
    __parameter_aggregate = ["aggregate_datatype"]
    __parameter_optional = ["optional_datatype"]

    # Ignored namespaces. Definition of algorithms start by looking into namespaces,
    # therefore ignoring some speeds up the traversal.
    __ignored_namespaces = ["std", "__gnu_cxx", "__cxxabiv1", "__gnu_debug"]

    # Arguments to pass to compiler, as function of file extension.
    __compile_flags = {
        "cuh": ["-x", "c++", "-std=c++17", "-nostdinc++"],
        "hpp": ["-std=c++17", "-nostdinc++"],
        "h": ["-std=c++17", "-nostdinc++"]
    }

    # Clang index
    __index = cindex.Index.create()

    # Property names
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
        """Traverses parameter / property c.

        For a parameter, we are searching for:
        * typename: Name of the class (ie. host_number_of_events_t).
        * kind: host / device.
        * io: input / output.
        * typedef: Type that it holds (ie. unsigned).

        For a property:
        * typedef: Type that it holds (ie. unsigned).
        * name: Name of the property (obtained with tokens)
        * descrition: Property description (obtained with tokens)
        """
        typename = c.spelling

        # Detect whether it is a parameter or a property
        is_property = False
        is_parameter = False
        for child in c.get_children():
            if child.kind == cindex.CursorKind.CXX_METHOD:
                if child.spelling == "parameter":
                    is_parameter = True
                elif child.spelling == "property":
                    is_property = True
        # Parse parameters / properties
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
                    # child.type.spelling is like "void (unsigned) const", or "void (unsigned)"
                    typedef = [a.type.spelling
                               for a in child.get_children()][0]
                    if child.result_type.get_num_template_arguments() > 1:
                        for i in range(1, child.result_type.get_num_template_arguments()):
                            dependencies.append(child.result_type.get_template_argument_type(i).spelling)
            if typedef == "" or typedef == "int" or aggregate:
                # This happens if the type cannot be parsed
                typedef = "unknown_t"
            if kind and typedef and io != None:
                return ("Parameter", typename, kind, io, typedef, aggregate, optional, dependencies)
        elif is_property:
            # - There is a function (property) which captures:
            #   * f.type.spelling: The type (restricted to POD types)
            typedef = None
            for child in c.get_children():
                if child.kind == cindex.CursorKind.CXX_METHOD:
                    typedef = [a.type.spelling
                               for a in child.get_children()][0]
            if typedef == "" or typedef == "int":
                # If the type is empty or int, it is not to be trusted and instead the tag is employed here
                typedef = AlgorithmTraversal.__properties[typename]["property_type"]
            # Unfortunately, for properties we need to rely on tokens found in the
            # namespace to get the literals.
            name = AlgorithmTraversal.__properties[typename]["name"]
            description = AlgorithmTraversal.__properties[typename][
                "description"]
            default_value = AlgorithmTraversal.__properties[typename][
                "default_value"]
            return ("Property", typename, typedef, name, description, default_value)
        return None

    @staticmethod
    def parameters(c):
        """Traverses all parameters / properties of an Algorithm."""
        if c.kind == cindex.CursorKind.STRUCT_DECL:
            return AlgorithmTraversal.traverse_individual_parameters(c)
        else:
            return None

    @staticmethod
    def algorithm_definition(c):
        """Traverses an algorithm definition. If a base class other than __algorithm_tokens
        is found, it delegates traversing the parameters / properties."""
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
            algorithm_parameters = ""
            algorithm_class_parameters = AlgorithmTraversal.traverse_children(
                c, AlgorithmTraversal.algorithm_definition)
            for d in algorithm_class_parameters:
                if len(d) > 2 and d[0] == "AlgorithmClass":
                    algorithm_class = d[2]
                elif type(d) == list:
                    algorithm_parameters = d
            if algorithm_class != "":
                return (c.kind, c.spelling, algorithm_class,
                        algorithm_parameters)
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
            # Check if it is a "new algorithm":
            if [a for a in AlgorithmTraversal.__algorithm_tokens if a in ts]:
                try:
                    last_found = -1
                    while True:
                        try:
                            last_found = ts.index("PROPERTY", last_found + 1)
                            typename = ts[last_found + 2]
                            name = ts[last_found + 4]
                            description = ts[last_found + 6]
                            closing_parenthesis = ts.index(")", last_found + 8)
                            property_type = "".join(ts[last_found + 8:closing_parenthesis])
                            AlgorithmTraversal.__properties[typename] = {
                                "name": name,
                                "description": description,
                                "property_type": property_type
                            }
                        except ValueError:
                            # Traverse the "Property"s to find out the default values
                            try:
                                last_found = ts.index("Property", last_found + 1)
                                typename = ts[last_found + 2]
                                comma_position = ts.index(",", last_found)
                                semicolon_position = ts.index(";", last_found)
                                default_value = "".join(ts[comma_position+1:semicolon_position-1])
                                AlgorithmTraversal.__properties[typename]["default_value"] = default_value
                            except ValueError:
                                break
                    return (c.kind, c.spelling,
                            AlgorithmTraversal.traverse_children(
                                c, AlgorithmTraversal.algorithm))
                except:
                    return None
        return None

    @staticmethod
    def traverse(filename, project_location="../"):
        """Opens the file with libClang, parses it and find algorithms.
        Returns a list of ParsedAlgorithms."""
        AlgorithmTraversal.__properties = {}
        extension = filename.split(".")[-1]
        try:
            clang_args = AlgorithmTraversal.__compile_flags[extension]
            clang_args.append("-I" + project_location + "/stream/gear/include")
            clang_args.append("-I" + project_location + "/backend/include")
            tu = AlgorithmTraversal.__index.parse(filename, args=clang_args)
            if tu.cursor.kind == cindex.CursorKind.TRANSLATION_UNIT:
                return make_parsed_algorithms(
                    filename,
                    AlgorithmTraversal.traverse_children(
                        tu.cursor, AlgorithmTraversal.namespace, filename))
            else:
                return None
        except IndexError:
            print("Filename of unexpected extension:", filename, extension)
