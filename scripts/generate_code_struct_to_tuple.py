#!/usr/bin/python3
###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################


def generate_code_struct_to_tuple(maximum_number_of_parameters):
    for i in range(maximum_number_of_parameters, 0, -1):
        s = "if constexpr(is_braces_constructible<type, "
        for j in range(i):
            s += "any_type, "
        s = s[:-2]
        s += ">{}) {\nauto&& ["
        for j in range(i):
            s += "p" + str(j) + ", "
        s = s[:-2]
        s += "] = object;\nreturn std::make_tuple("
        for j in range(i):
            s += "p" + str(j) + ", "
        s = s[:-2]
        s += ");\n} else "
        print(s)
    print("{\nreturn std::make_tuple();\n}")


generate_code_struct_to_tuple(40)
