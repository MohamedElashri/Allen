import clang.cindex as cindex


class ParsedLine():
    def __init__(self, name, line_type, namespace, filename):
        self.name = name
        self.line_type = line_type
        self.namespace = namespace
        self.filename = filename

    def __repr__(self):
        return self.line_type + " " + self.name


def make_parsed_lines(filename, data):
    parsed_lines = []
    for namespace_data in data:
        line_data = namespace_data[2]
        if len(line_data) > 0:
            line_description = line_data[0]
            # There is a line defined here, fetch it
            namespace = namespace_data[1]
            name = line_description[1]
            line_type = line_description[2]
            parsed_lines.append(
                ParsedLine(name, line_type, namespace, filename))
    return parsed_lines


class LineTraversal():
    """Static class that traverses the code defining lines.
    This algorithm traversal operates on include files.
    The following syntax is required from an algorithm:

    namespace X {
        struct Y : <Linetype> {
            ...
        };
    }"""

    # Accepted tokens for line definitions
    # TODO: This should be automatically fetched
    __line_tokens = [
        "Line", "SpecialLine", "VeloLine", "OneTrackLine", "TwoTrackLine",
        "VeloUTTwoTrackLine", "ThreeTrackLine", "FourTrackLine"
    ]

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
    def line(c):
        """Traverses a line. First, it identifies whether the struct has
        either of the accepted class types among its tokens. If so,
        it proceeds to find algorithm parameters, template parameters, and returns a triplet:
        (kind, spelling, line type)."""
        if c.kind == cindex.CursorKind.STRUCT_DECL:
            # Detecting inheritance from the algorithm needs to be done with tokens so far
            line_type = None
            for t in c.get_tokens():
                if t.spelling in LineTraversal.__line_tokens:
                    line_type = t.spelling
                    break
            if line_type is not None:
                return (c.kind, c.spelling, line_type)
            else:
                return None
        else:
            return None

    @staticmethod
    def namespace(c, filename):
        """Traverses the namespaces."""
        if (c.kind == cindex.CursorKind.NAMESPACE
                and c.spelling not in LineTraversal.__ignored_namespaces
                and c.location.file.name == filename):
            return (c.kind, c.spelling,
                    LineTraversal.traverse_children(c, LineTraversal.line))
        else:
            return None

    @staticmethod
    def traverse(filename):
        """Opens the file with libClang, parses it and find lines.
        Returns a list of ParsedLines."""
        extension = filename.split(".")[-1]
        try:
            clang_args = LineTraversal.__compile_flags[extension]
            tu = LineTraversal.__index.parse(filename, args=clang_args)
            if tu.cursor.kind == cindex.CursorKind.TRANSLATION_UNIT:
                return make_parsed_lines(
                    filename,
                    LineTraversal.traverse_children(
                        tu.cursor, LineTraversal.namespace, filename))
            else:
                return None
        except IndexError:
            print("Filename of unexpected extension:", filename, extension)
