import clang.cindex as cindex
from IPython import embed


class ParsedAlgorithm():
    def __init__(self, name, scope, filename, namespace,
                 parameters, properties):
        self.name = name
        self.scope = scope
        self.filename = filename
        self.namespace = namespace
        self.parameters = parameters
        self.properties = properties

    def __repr__(self):
        return self.scope + " " + self.name


class Property():
    def __init__(self, kind, typename, typedef, name, description):
        self.kind = kind
        self.typename = typename
        self.typedef = typedef
        self.name = name
        self.description = description


class Parameter():
    def __init__(self, kind, typename, typedef):
        self.kind = kind
        self.typename = typename
        self.typedef = typedef


def make_parsed_algorithms(filename, data):
    parsed_algorithms = []
    for namespace_data in data:
        algorithm_data = namespace_data[2]
        if len(algorithm_data) > 0:
            algorithm_description = algorithm_data[0]
            # There is an algorithm defined here, fetch it
            namespace = namespace_data[1]
            name = algorithm_description[1]
            scope = algorithm_description[2]
            parameters = []
            properties = []
            for t in algorithm_description[3][0]:
                kind = t[1]
                typename = t[2][0]
                typedef = t[2][1]
                if kind == "PROPERTY":
                    property_name = t[2][2]
                    property_description = t[2][3]
                    properties.append(
                        Property(kind, typename, typedef, property_name,
                                 property_description))
                else:
                    parameters.append(Parameter(kind, typename, typedef))
            parsed_algorithms.append(
                ParsedAlgorithm(name, scope, filename, namespace,
                                parameters, properties))
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
    __algorithm_tokens = ["HostAlgorithm", "DeviceAlgorithm"]

    # Ignored namespaces. Definition of algorithms start by looking into namespaces,
    # therefore ignoring some speeds up the traversal.
    __ignored_namespaces = ["std", "__gnu_cxx", "__cxxabiv1", "__gnu_debug"]

    # Arguments to pass to compiler, as function of file extension.
    __compile_flags = {
        "cuh": ["-x", "cuda", "-std=c++14", "-nostdinc++", "-I../stream/gear/include"],
        "hpp": ["-std=c++17"],
        "h": ["-std=c++17"]
    }

    # Clang index
    __index = cindex.Index.create()

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
        """Traverses individual tokens from parameter c."""
        tokens = []
        for t in c.get_tokens():
            tokens.append(t)
        if tokens[0].spelling == "PROPERTY":
            class_spelling_tokens = [a.spelling for a in tokens[4:]]
            location_enclosing_token = class_spelling_tokens.index(",")
            class_name = "".join(
                class_spelling_tokens[:location_enclosing_token])
            return (tokens[2].spelling, class_name,
                    tokens[4 + location_enclosing_token + 1].spelling,
                    tokens[4 + location_enclosing_token + 3].spelling)
        else:
            class_spelling_tokens = [a.spelling for a in tokens[4:]]
            location_enclosing_token = class_spelling_tokens.index(")")
            class_name = "".join(
                class_spelling_tokens[:location_enclosing_token])
            return (tokens[2].spelling, class_name)

    @staticmethod
    def parameters(c):
        """Traverses all parameters of an Algorithm."""
        if c.kind == cindex.CursorKind.STRUCT_DECL:
            return (c.kind, c.spelling, c)
            # AlgorithmTraversal.traverse_individual_parameters(c)
        else:
            return None

    @staticmethod
    def algorithm_definition(c):
        """Traverses an algorithm definition. Once a base class is found (Parameters),
        it delegates traversing the parameters."""
        if c.kind == cindex.CursorKind.CXX_BASE_SPECIFIER:
            if c.type.spelling in AlgorithmTraversal.__algorithm_tokens:
                return ("AlgorithmClass", c.kind, c.type.spelling)
            else:
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
        if c.kind == cindex.CursorKind.CLASS_TEMPLATE:
            # Fetch the class and parameters of the algorithm
            algorithm_class = ""
            algorithm_parameters = ""
            algorithm_class_parameters = AlgorithmTraversal.traverse_children(
                c, AlgorithmTraversal.algorithm_definition)
            for d in algorithm_class_parameters:
                if len(d) > 0 and d[0] == "AlgorithmClass":
                    algorithm_class = d[2]
            # TODO: For parameters:
            #       - Host / Device is now visible as a child class.
            #       - There is a function (foo) which captures:
            #         * f.is_const_method(): Input / Output
            #         * f.type.spelling: The type (restricted to POD types, others decay to int)
            embed()
            return (c.kind, c.spelling,
                    algorithm_class, algorithm_parameters)
        else:
            return None

    @staticmethod
    def namespace(c, filename):
        """Traverses the namespaces."""
        if c.kind == cindex.CursorKind.NAMESPACE and c.spelling not in AlgorithmTraversal.__ignored_namespaces and \
            c.location.file.name == filename:
            return (c.kind, c.spelling,
                    AlgorithmTraversal.traverse_children(
                        c, AlgorithmTraversal.algorithm))
        else:
            return None

    @staticmethod
    def traverse(filename):
        """Opens the file with libTooling, parses it and find algorithms.
        Returns a list of ParsedAlgorithms."""
        extension = filename.split(".")[-1]
        try:
            clang_args = AlgorithmTraversal.__compile_flags[extension]
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
