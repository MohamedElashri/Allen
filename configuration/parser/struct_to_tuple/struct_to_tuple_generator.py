#!/usr/bin/python3
###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################


class StructToTupleGenerator:
    def __init__(self):
        self.pre_filename = "struct_to_tuple/StructToTuple_pre.cuh"
        self.post_filename = "struct_to_tuple/StructToTuple_post.cuh"

    def __generate_code_struct_to_tuple(self, maximum_number_of_parameters):
        s = ""
        for i in range(maximum_number_of_parameters, 0, -1):
            s += "  if constexpr(is_braces_constructible<type, "
            for j in range(i):
                s += "any_type, "
            s = s[:-2]
            s += ">) {\n    auto&& ["
            for j in range(i):
                s += "p" + str(j) + ", "
            s = s[:-2]
            s += "] = object;\n    return std::make_tuple("
            for j in range(i):
                s += "p" + str(j) + ", "
            s = s[:-2]
            s += ");\n  } else "
        s += "{\n    return std::make_tuple();\n  }"
        return s

    def generate_file(self, output_filename, maximum_number_of_parameters):
        s = ""
        with open(self.pre_filename) as f:
            s += f.read()
        s += self.__generate_code_struct_to_tuple(maximum_number_of_parameters)
        with open(self.post_filename) as f:
            s += f.read()
        with open(output_filename, "w") as f:
            f.write(s)
