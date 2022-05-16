#!/usr/bin/python3
###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################


class StructToTupleGenerator:
    def __generate_code_struct_to_tuple_fn(self, maximum_number_of_parameters, style="new"):
        s = "\n".join(["/**",
            " * @brief Struct to tuple conversion using structured binding.",
            " */",
            "template<class T>",
            "__host__ __device__ auto struct_to_tuple(T&& object) noexcept",
            "{",
            "  using type = std::decay_t<T>;"
        ])

        for i in range(maximum_number_of_parameters, 0, -1):
            s += "  if constexpr(is_braces_constructible<type, "
            for j in range(i):
                s += "any_type"
                if j != i - 1:
                    s += ", "
            s += ">) {\n    auto&& ["
            for j in range(i):
                s += "p" + str(j)
                if j != i - 1:
                    s += ", "
            s += "] = object;\n"
            if style == "new":
                s += "    return std::tuple{"
            else:
                s += "    return std::make_tuple("
            for j in range(i):
                s += "p" + str(j)
                if j != i - 1:
                    s += ", "
            if style == "new":
                s += "};\n"
            else:
                s += ");\n"
            s += "  } else "
        s += "\n".join(["{",
            "    return std::tuple{};",
            "  }",
            "}"])
        return s


    def __generate_code_struct_to_tuple(self, maximum_number_of_parameters):
        s = "\n".join([
            "/**",
            " * @brief This file implements struct to tuple conversion with structured bindings.",
            " */",
            "",
            "#include <tuple>",
            "#include <type_traits>",
            "#include <cassert>",
            "",
            "namespace details {",
            "  /// Implementation of the detection idiom (negative case).",
            "  template<typename AlwaysVoid, template<typename...> class Op, typename... Args>",
            "  struct detector {",
            "    constexpr static bool value = false;",
            "  };",
            "",
            "  /// Implementation of the detection idiom (positive case).",
            "  template<template<typename...> class Op, typename... Args>",
            "  struct detector<std::void_t<Op<Args...>>, Op, Args...> {",
            "    constexpr static bool value = true;",
            "  };",
            "} // namespace details",
            "",
            "template<template<class...> class Op, class... Args>",
            "using is_detected_st = details::detector<void, Op, Args...>;",
            "",
            "template<template<class...> class Op, class... Args>",
            "inline constexpr bool is_detected_st_v = is_detected_st<Op, Args...>::value;",
            "",
            "template<typename T, typename... Args>",
            "using braced_init = decltype(T {std::declval<Args>()...});",
            "",
            "// This is not even my final form",
            "template<typename... Args>",
            "inline constexpr bool is_braces_constructible = is_detected_st_v<braced_init, Args...>;",
            "",
            "struct any_type {",
            "  template<class T>",
            "  constexpr operator T(); // non explicit",
            "};",
            "",
            "// Avoid wrong warnings from nvcc:",
            "// Warning #940-D: missing return statement at end of non-void function struct_to_tuple(T &&)",
            "#ifdef __CUDACC__",
            "#pragma push",
            "#if __CUDACC_VER_MAJOR__ > 11 || (__CUDACC_VER_MAJOR__ == 11 && __CUDACC_VER_MINOR__ >= 6)",
            "#pragma nv_diag_suppress = 940",
            "#else",
            "#pragma diag_suppress = 940",
            "#endif",
            "#endif",
            "",
            "#if defined(__CUDACC__) && (__CUDACC_VER_MAJOR__ < 11 || (__CUDACC_VER_MAJOR__ == 11 && __CUDACC_VER_MINOR__ < 7))",
            self.__generate_code_struct_to_tuple_fn(maximum_number_of_parameters, "old"),
            "#else",
            self.__generate_code_struct_to_tuple_fn(maximum_number_of_parameters, "new"),
            "#endif",
            "#ifdef __CUDACC__",
            "#pragma pop",
            "#endif"])
        return s


    def generate_file(self, output_filename, maximum_number_of_parameters,
                      struct_to_tuple_folder):
        with open(output_filename, "w") as f:
            f.write(self.__generate_code_struct_to_tuple(maximum_number_of_parameters))
