import clang.cindex as cindex


class ParsedAlgorithm():
    def __init__(self, name, scope, filename, namespace, threetemplate, parameters, properties):
        self.name = name
        self.scope = scope
        self.filename = filename
        self.namespace = namespace
        self.threetemplate = threetemplate
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
            threetemplate = algorithm_description[2] == 3
            scope = algorithm_description[3]
            parameters = []
            properties = []
            for t in algorithm_description[4][0]:
                kind = t[1]
                typename = t[2][0]
                typedef = t[2][1]
                if kind == "PROPERTY":
                    property_name = t[2][2]
                    property_description = t[2][3]
                    properties.append(Property(kind, typename, typedef, property_name, property_description))
                else:
                    parameters.append(Parameter(kind, typename, typedef))
            parsed_algorithms.append(ParsedAlgorithm(name, scope, filename, namespace, threetemplate, parameters, properties))
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
    __compile_flags = {"cuh": ["-x", "cuda", "-std=c++14"], "hpp": ["-std=c++17"], "h": ["-std=c++17"]}

    # Clang index
    __index = cindex.Index.create()

    @staticmethod
    def traverse_children(c, f):
        """ Traverses the children of a cursor c by applying function f.
        Returns a list of traversed objects. If the result of traversing
        an object is None, it is ignored."""
        return_object = []
        for child_node in c.get_children():
            parsed_children = f(child_node)
            if parsed_children.__class__ != None.__class__:
                return_object.append(parsed_children)
        return return_object

    @staticmethod
    def traverse_individual_parameters(c):
        """Traverses individual tokens from parameter c."""
        tokens = []
        for t in c.get_tokens():
            tokens.append(t)
        if tokens[0].spelling == "PROPERTY":
            return (tokens[2].spelling, tokens[4].spelling, tokens[6].spelling, tokens[8].spelling)
        return (tokens[2].spelling, tokens[4].spelling)

    @staticmethod
    def parameters(c):
        """Traverses all parameters of an Algorithm."""
        if c.kind == cindex.CursorKind.CXX_METHOD:
            return (c.kind, c.spelling, AlgorithmTraversal.traverse_individual_parameters(c))
        else:
            return None

    @staticmethod
    def algorithm_definition(c):
        """Traverses an algorithm definition. Once a base class is found (Parameters),
        it delegates traversing the parameters."""
        if c.kind == cindex.CursorKind.CXX_BASE_SPECIFIER:
            return AlgorithmTraversal.traverse_children(c.get_definition(), AlgorithmTraversal.parameters)
        else:
            return None

    @staticmethod
    def algorithm_templates(c):
        """Fetch how many template parameters this struct has."""
        if c.kind == cindex.CursorKind.TEMPLATE_TYPE_PARAMETER or c.kind == cindex.CursorKind.TEMPLATE_NON_TYPE_PARAMETER:
            return 1
        else:
            return None

    @staticmethod
    def algorithm(c):
        """Traverses an algorithm. First, it identifies whether the struct has
        either "HostAlgorithm" or "DeviceAlgorithm" among its tokens. If so,
        it proceeds to find algorithm parameters, template parameters, and returns a quintuplet:
        (kind, spelling, number of template parameters, algorithm class, algorithm parameters)."""
        if c.kind == cindex.CursorKind.CLASS_TEMPLATE:
            # Detecting inheritance from the algorithm needs to be done with tokens so far
            algorithm_class = None
            for t in c.get_tokens():
                if t.spelling in AlgorithmTraversal.__algorithm_tokens:
                    algorithm_class = t.spelling
                    break
            if algorithm_class is not None:
                # Fetch the parameters of the algorithm
                algorithm_parameters = AlgorithmTraversal.traverse_children(c, AlgorithmTraversal.algorithm_definition)
                template_parameters = len(AlgorithmTraversal.traverse_children(c, AlgorithmTraversal.algorithm_templates))
                return (c.kind, c.spelling, template_parameters, algorithm_class, algorithm_parameters)
            else:
                return None
        else:
            return None

    @staticmethod
    def namespace(c):
        """Traverses the namespaces."""
        if c.kind == cindex.CursorKind.NAMESPACE and c.spelling not in AlgorithmTraversal.__ignored_namespaces:
            return (c.kind, c.spelling, AlgorithmTraversal.traverse_children(c, AlgorithmTraversal.algorithm))
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
                return make_parsed_algorithms(filename, AlgorithmTraversal.traverse_children(tu.cursor, AlgorithmTraversal.namespace))
            else:
                return None
        except IndexError:
            print("Filename of unexpected extension:", filename, extension)
