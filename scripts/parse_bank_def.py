import clang.cindex
from subprocess import Popen, PIPE
import os
import argparse
import sys
import pprint

arg_parser = argparse.ArgumentParser()
arg_parser.add_argument('header')
arg_parser.add_argument('-o', '--output-opts', dest='opts', type=str,
                        default='allen_opts.py')
args = arg_parser.parse_args()


def compiler_preprocessor_verbose(compiler, extraflags):
    """Capture the compiler preprocessor stage in verbose mode
    """
    lines = []
    with open(os.devnull, 'r') as devnull:
        cmd = [compiler, '-E']
        cmd += extraflags
        cmd += ['-', '-v']
        p = Popen(cmd, stdin=devnull, stdout=PIPE, stderr=PIPE)
        p.wait()
        p.stdout.close()
        lines = p.stderr.read()
        lines = lines.decode('utf-8')
        lines = lines.splitlines()
    return lines


def system_include_paths(compiler, cpp=True):
    extraflags = []
    if cpp:
        extraflags = '-x c++'.split()
    lines = compiler_preprocessor_verbose(compiler, extraflags)
    lines = [line.strip() for line in lines]

    start = lines.index('#include <...> search starts here:')
    end = lines.index('End of search list.')

    lines = lines[start+1:end]
    paths = []
    for line in lines:
        line = line.replace('(framework directory)', '')
        line = line.strip()
        paths.append(line)
    return paths


clang_args = ["-x", "cuda", "-std=c++14"]
include_paths = system_include_paths("clang++")
clang_args += [(b'-I' + inc).decode("utf-8") for inc in include_paths]


def get_annotations(node):
    return [c.displayname for c in node.get_children()
            if c.kind == clang.cindex.CursorKind.ANNOTATE_ATTR]


class Enum(object):
    def __init__(self, cursor):
        self.name = cursor.spelling
        self.constants = [c.spelling for c in cursor.get_children()
                          if c.kind == clang.cindex.CursorKind.ENUM_CONSTANT_DECL]
        self.documentation = cursor.raw_comment


class Class(object):
    def __init__(self, cursor):
        self.name = cursor.spelling
#        self.functions = []
        self.annotations = get_annotations(cursor)


def traverse(c, path, objects, namespace):
    if c.location.file and not c.location.file.name.endswith(path):
        return

    if c.kind == clang.cindex.CursorKind.TRANSLATION_UNIT or c.kind == clang.cindex.CursorKind.UNEXPOSED_DECL:
        # Ignore  other cursor kinds
        pass

    elif c.kind == clang.cindex.CursorKind.NAMESPACE:
        if namespace :
            namespace = namespace + tuple([c.spelling])
        else:
            namespace = tuple([c.spelling])
        if namespace not in objects:
            objects[namespace] = []
        pass

#     elif c.kind == clang.cindex.CursorKind.FUNCTION_TEMPLATE:
# #        print("Function Template", c.spelling, c.raw_comment)
#         objects["functions"].append(Function(c))
#         return

#     elif c.kind == clang.cindex.CursorKind.FUNCTION_DECL:
#         # print("FUNCTION_DECL", c.spelling, c.raw_comment)
#         objects["functions"].append(Function(c))
#         return

    elif c.kind == clang.cindex.CursorKind.ENUM_DECL:
        # print("ENUM_DECL", c.spelling, c.raw_comment)
        objects[namespace].append(Enum(c))
        return

    elif c.kind == clang.cindex.CursorKind.CLASS_DECL:
        objects[namespace].append(Class(c))
        return

    elif c.kind == clang.cindex.CursorKind.CLASS_TEMPLATE:
        objects[namespace].append(Class(c))
        return

    elif c.kind == clang.cindex.CursorKind.STRUCT_DECL:
        objects[namespace].append(Class(c))
        return

    else:
        pass

    for child_node in c.get_children():
        traverse(child_node, path, objects, namespace)


opts = {'HltANNSvc': {'Hlt1SelectionID': {}},
        'ExecutionReportsWriter': {'Persist': []}}

index = clang.cindex.Index.create()
error = None
try:
    tu = index.parse(args.header, args=clang_args)
    objects = {}
    traverse(tu.cursor, args.header, objects, ())
    if ('Hlt1',) in objects:
        enums = {o.name: o for o in objects[('Hlt1',)] if type(o) is Enum}
        lines_enum = enums.get('Hlt1Lines', None)
        if lines_enum is not None:
            for i, c in enumerate(lines_enum.constants):
                if c == 'End':
                    continue
                line = 'Hlt1%sLine' % c
                opts['HltANNSvc']['Hlt1SelectionID'][line] = i
                opts['ExecutionReportsWriter']['Persist'].append(line)
            with open(args.opts, 'w') as output:
                pprint.pprint(opts, output)
except clang.cindex.TranslationUnitLoadError as e:
    print(e)
    sys.exit(-1)
