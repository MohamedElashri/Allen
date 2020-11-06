###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import clang.cindex as cindex
from IPython import embed


class ParsedAlgorithm():
    def __init__(self, name, scope, filename, namespace, parameters,
                 properties):
        self.name = name
        self.scope = scope
        self.filename = filename
        self.namespace = namespace
        self.parameters = parameters
        self.properties = properties

    def __repr__(self):
        return self.scope + " " + self.name


class Property():
    def __init__(self, typename, typedef, name, description):
        self.typename = typename
        self.typedef = typedef
        self.name = name
        self.description = description


class Parameter():
    def __init__(self, typename, datatype, is_input, typedef, aggregate):
        self.typename = typename
        self.typedef = typedef
        self.aggregate = aggregate
        if datatype == "host_datatype" and is_input:
            self.kind = "HostInput"
        elif datatype == "host_datatype" and not is_input:
            self.kind = "HostOutput"
        elif datatype == "device_datatype" and is_input:
            self.kind = "DeviceInput"
        elif datatype == "device_datatype" and not is_input:
            self.kind = "DeviceOutput"
        else:
            raise


# TODO: Parse these from Algorithm.cuh
def make_default_algorithm_properties():
    return [
        Property("verbosity_t", "int", "\"verbosity\"",
                 "\"verbosity of algorithm\"")
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
                    typename = t[1]
                    typedef = t[2]
                    prop_name = t[3]
                    description = t[4]
                    properties.append(
                        Property(typename, typedef, prop_name, description))
                elif kind == "Parameter":
                    typename = t[1]
                    datatype = t[2]
                    is_input = t[3]
                    typedef = t[4]
                    aggregate = t[5]
                    parameters.append(
                        Parameter(typename, datatype, is_input, typedef,
                                  aggregate))
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

    # Accepted tokens for algorithm definitions
    __algorithm_tokens = [
        "HostAlgorithm", "DeviceAlgorithm", "SelectionAlgorithm"
    ]

    # Accepted tokens for parameter parsing
    __parameter_io_datatypes = ["device_datatype", "host_datatype"]
    __parameter_aggregate = ["aggregate_datatype"]

    # Ignored namespaces. Definition of algorithms start by looking into namespaces,
    # therefore ignoring some speeds up the traversal.
    __ignored_namespaces = ["std", "__gnu_cxx", "__cxxabiv1", "__gnu_debug"]

    # Arguments to pass to compiler, as function of file extension.
    __compile_flags = {
        "cuh": ["-x", "cuda", "-std=c++14", "-nostdinc++"],
        "hpp": ["-std=c++17"],
        "h": ["-std=c++17"]
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
            for child in c.get_children():
                if child.kind == cindex.CursorKind.CXX_BASE_SPECIFIER and child.type.spelling in AlgorithmTraversal.__parameter_io_datatypes:
                    kind = child.type.spelling
                elif child.kind == cindex.CursorKind.CXX_BASE_SPECIFIER and child.type.spelling in AlgorithmTraversal.__parameter_aggregate:
                    aggregate = True
                elif child.kind == cindex.CursorKind.CXX_METHOD:
                    io = child.is_const_method()
                    # child.type.spelling is like "void (unsigned) const", or "void (unsigned)"
                    typedef = child.type.spelling[child.type.spelling.find(
                        "(") + 1:child.type.spelling.find(")")]
            if typedef == "":
                # This happens if the type cannot be parsed
                typedef = "int"
            if kind and typedef and io != None:
                return ("Parameter", typename, kind, io, typedef, aggregate)
        elif is_property:
            # - There is a function (property) which captures:
            #   * f.type.spelling: The type (restricted to POD types)
            typedef = None
            for child in c.get_children():
                if child.kind == cindex.CursorKind.CXX_METHOD:
                    typedef = child.type.spelling[child.type.spelling.find(
                        "(") + 1:child.type.spelling.find(")")]
            if typedef == "":
                typedef = "int"
            # Unfortunately, for properties we need to rely on tokens found in the
            # namespace to get the literals.
            name = AlgorithmTraversal.__properties[typename]["name"]
            description = AlgorithmTraversal.__properties[typename][
                "description"]
            return ("Property", typename, typedef, name, description)
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
        either "HostAlgorithm" or "DeviceAlgorithm" among its tokens. If so,
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
            if "DeviceAlgorithm" in ts or "HostAlgorithm" in ts or "SelectionAlgorithm" in ts:
                try:
                    last_found = -1
                    while True:
                        try:
                            last_found = ts.index("PROPERTY", last_found + 1)
                            typename = ts[last_found + 2]
                            name = ts[last_found + 4]
                            description = ts[last_found + 6]
                            AlgorithmTraversal.__properties[typename] = {
                                "name": name,
                                "description": description
                            }
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
