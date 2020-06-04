class Sequence():
    def __init__(self, *args):
        self.__sequence = OrderedDict()
        if type(args[0]) == list:
            for item in args[0]:
                if issubclass(type(item), Algorithm):
                    self.__sequence[item.name()] = item
        else:
            for item in args:
                if issubclass(type(item), Algorithm):
                    self.__sequence[item.name()] = item

    def validate(self):
        warnings = 0
        errors = 0

        # Check there are not two outputs with the same name
        output_names = OrderedDict([])
        for _, algorithm in iter(self.__sequence.items()):
            for parameter_name, parameter in iter(
                    algorithm.parameters().items()):
                if issubclass(parameter.__class__, OutputParameter):
                    if parameter.fullname() in output_names:
                        output_names[parameter.fullname()].append(
                            algorithm.name())
                    else:
                        output_names[parameter.fullname()] = [algorithm.name()]

        for k, v in iter(output_names.items()):
            # Note: This is a warning, as the sequence atm contains this
            if len(v) > 1:
                print(
                    "Warning: OutputParameter \"" + k +
                    "\" appears on algorithms: ",
                    end="")
                i = 0
                for algorithm_name in v:
                    i += 1
                    print(algorithm_name, end="")
                    if i != len(v):
                        print(", ", end="")
                print()
                warnings += 1

        # Check the inputs of all algorithms
        output_parameters = OrderedDict([])
        for _, algorithm in iter(self.__sequence.items()):
            for parameter_name, current_parameter in iter(
                    algorithm.parameters().items()):
                for parameter in parameter_tuple(current_parameter):
                    if issubclass(type(parameter), InputParameter):
                        # Check the input is not orphaned (ie. that there is a previous Output that generated it)
                        if parameter.fullname() not in output_parameters:
                            print("Error: Parameter " + repr(parameter) + " of algorithm " + algorithm.name() + \
                              " is an InputParameter not provided by any previous OutputParameter.")
                            errors += 1
                        # Check that the input and output types correspond
                        if parameter.fullname() in output_parameters and \
                          output_parameters[parameter.fullname()]["parameter"].type() != parameter.type():
                            print("Error: Type mismatch (" + repr(parameter.type()) + ", " + repr(output_parameters[parameter.fullname()]["parameter"].type()) + ") " \
                              + "between " + algorithm.name() + "::" + repr(parameter) \
                              + " and " + output_parameters[parameter.fullname()]["algorithm"].name() \
                              + "::" + repr(output_parameters[parameter.fullname()]["parameter"]))
                            errors += 1
                        # Check the scope (Device, Host) of the input and output parameters matches
                        if parameter.fullname() in output_parameters and \
                          ((issubclass(parameter.__class__, DeviceParameter) and \
                            issubclass(output_parameters[parameter.fullname()]["parameter"].__class__, HostParameter)) or \
                          (issubclass(parameter.__class__, HostParameter) and \
                            issubclass(output_parameters[parameter.fullname()]["parameter"].__class__, DeviceParameter))):
                            print("Error: Scope mismatch (" + parameter.__class__ + ", " + output_parameters[parameter.fullname()]["parameter"].__class__ + ") " \
                              + "of InputParameter " + repr(parameter) + " of algorithm " + algorithm.name())
                            errors += 1
            for parameter_name, parameter in iter(
                    algorithm.parameters().items()):
                if issubclass(parameter.__class__, OutputParameter):
                    output_parameters[parameter.fullname()] = {
                        "parameter": parameter,
                        "algorithm": algorithm
                    }

        if errors >= 1:
            print("Number of sequence errors:", errors)
            return False
        elif warnings >= 1:
            print("Number of sequence warnings:", warnings)

        return True

    def generate(self,
                 output_filename="Sequence.h",
                 aggregate_input_filename="ConfiguredInputAggregates.h",
                 json_configuration_filename="Sequence.json",
                 prefix_includes="../../"):
        # Check that sequence is valid
        print("Validating sequence...")
        if self.validate():
            # Add all the includes
            s = "#pragma once\n\n#include <tuple>\n"
            s += "#include \"" + aggregate_input_filename + "\"\n"
            s += "#include \"" + prefix_includes + "stream/gear/include/ArgumentManager.cuh\"\n"
            for _, algorithm in iter(self.__sequence.items()):
                s += "#include \"" + prefix_includes + algorithm.filename(
                ) + "\"\n"
            s += "\n"
            # Generate all parameters
            parameters = OrderedDict([])
            parameters_part_of_aggregates = OrderedDict([])
            for _, algorithm in iter(self.__sequence.items()):
                for parameter_t, parameter in iter(
                        algorithm.parameters().items()):
                    if type(parameter) != tuple:
                        if parameter.fullname() in parameters:
                            parameters[parameter.fullname()].append((algorithm.name(), algorithm.namespace, parameter_t))
                        else:
                            parameters[parameter.fullname()] = [(algorithm.name(), algorithm.namespace, parameter_t)]
                    else:
                        for p in parameter:
                            parameters_part_of_aggregates[p.fullname()] = p
            # Generate arguments
            for parameter_name, v in iter(parameters.items()):
                if parameter_name not in parameters_part_of_aggregates:
                    s += "struct " + parameter_name + " : "
                    inheriting_classes = []
                    for algorithm_name, algorithm_namespace, parameter_t in v:
                        parameter = algorithm_namespace + "::Parameters::" + parameter_t
                        if parameter not in inheriting_classes:
                            inheriting_classes.append(parameter)
                    for inheriting_class in inheriting_classes:
                        s += inheriting_class + ", "
                    s = s[:-2]
                    s += " { \
using type = " + v[0][1] + "::Parameters::" + v[0][2] + "::type; \
void set_size(size_t size) override { m_size = size; } \
size_t size() const override { return m_size; } \
std::string name() const override { return \"" + parameter_name + "\"; } \
void set_offset(char* offset) override { m_offset = offset; } \
char* offset() const override { return m_offset; } \
private: \
size_t m_size = 0; \
char* m_offset = nullptr; };\n"

            # Generate argument tuple
            s += "\nusing configured_arguments_t = std::tuple<\n"
            for parameter_name in parameters.keys():
                s += prefix(1) + parameter_name + ",\n"
            s = s[:-2] + ">;\n"
            # Generate sequence
            s += "\nusing configured_sequence_t = std::tuple<\n"
            i_alg = 0
            for _, algorithm in iter(self.__sequence.items()):
                i_alg += 1
                # Add algorithm namespace::name
                s += prefix(1) + algorithm.namespace + "::" + algorithm.original_name()
                i = 0
                if i_alg != len(self.__sequence):
                    s += ",\n"
            s += ">;\n\n"
            # Generate argument tuple for each step of the sequence
            s += "using configured_sequence_arguments_t = std::tuple<\n"
            for _, algorithm in iter(self.__sequence.items()):
                s += prefix(1) + "std::tuple<"
                i = 0
                for parameter_t, current_parameter in iter(
                        algorithm.parameters().items()):
                    for parameter in parameter_tuple(current_parameter):
                        s += parameter.fullname()
                        i += 1
                        s += ", "
                s = s[:-2] + ">,\n"
            s = s[:-2] + ">;\n\n"
            # Generate populate_sequence_algorithm_names function
            s += "void inline populate_sequence_algorithm_names(configured_sequence_t& sequence) {\n"
            i = 0
            for _, algorithm in iter(self.__sequence.items()):
                s += prefix(1) + "std::get<" + str(
                    i) + ">(sequence).set_name(\"" + algorithm.name(
                    ) + "\");\n"
                i += 1
            s += "}\n"
            f = open(output_filename, "w")
            f.write(s)
            f.close()
            print("Generated sequence file " + output_filename)
            # Generate input aggregates file
            s = "#pragma once\n\n#include <tuple>\n"
            algorithms_with_aggregates_list = algorithms_with_aggregates()
            parameter_producers = set([])
            for producer_filename in set([self.__sequence[parameter.producer()].filename() for _, parameter in parameters_part_of_aggregates.items()]):
                s += "#include \"" + prefix_includes + producer_filename + "\"\n"
            s += "\n"
            # Generate typenames that participate in aggregates
            for parameter_name in parameters_part_of_aggregates:
                v = parameters[parameter_name]
                s += "struct " + parameter_name + " : "
                inheriting_classes = []
                for algorithm_name, algorithm_namespace, parameter_t in v:
                    parameter = algorithm_namespace + "::Parameters::" + parameter_t
                    if parameter not in inheriting_classes:
                        inheriting_classes.append(parameter)
                for inheriting_class in inheriting_classes:
                    s += inheriting_class + ", "
                s = s[:-2]
                s += " { \
using type = " + v[0][1] + "::Parameters::" + v[0][2] + "::type; \
void set_size(size_t size) override { m_size = size; } \
size_t size() const override { return m_size; } \
std::string name() const override { return \"" + parameter_name + "\"; } \
void set_offset(char* offset) override { m_offset = offset; } \
char* offset() const override { return m_offset; } \
private: \
size_t m_size = 0; \
char* m_offset = nullptr; };\n"
            s += "\n"
            for algorithm_with_aggregate_class in algorithms_with_aggregates_list:
                instance_of_alg_class = [alg for _, alg in self.__sequence.items() if type(alg) == algorithm_with_aggregate_class]
                if len(instance_of_alg_class):
                    for algorithm in instance_of_alg_class:
                        for parameter_t, parameter_tup in iter(algorithm.parameters().items()):
                            if type(parameter_tup) == tuple:
                                s += "namespace " + algorithm.namespace + " { namespace " + parameter_t + " { using tuple_t = std::tuple<"
                                for parameter in parameter_tup:
                                    s += parameter.fullname() + ", "
                                s = s[:-2] + ">; }}\n"
                else:
                    # Since there are no instances of that algorithm,
                    # at least we need to populate the aggregate inputs as empty
                    for aggregate_parameter in algorithm_with_aggregate_class.aggregates:
                        print(algorithm_with_aggregate_class.namespace)
                        s += "namespace " + algorithm_with_aggregate_class.namespace + " { namespace " + aggregate_parameter + " { using tuple_t = std::tuple<>; }}\n"
            f = open(aggregate_input_filename, "w")
            f.write(s)
            f.close()
            print("Generated multiple input configuration file " +
                  aggregate_input_filename)
            # Generate runtime configuration (JSON)
            s = "{\n"
            i = 1
            for _, algorithm in iter(self.__sequence.items()):
                has_modified_properties = False
                for prop_name, prop in iter(algorithm.properties().items()):
                    if prop.value() != "":
                        has_modified_properties = True
                        break
                if has_modified_properties:
                    s += prefix(i) + "\"" + algorithm.name() + "\": {"
                    for prop_name, prop in iter(
                            algorithm.properties().items()):
                        if prop.value() != "":
                            s += "\"" + prop_name + "\": \"" + prop.value(
                            ) + "\", "
                    s = s[:-2]
                    s += "},\n"
            s += prefix(i) + "\"configured_lines\": ["
            selection_algorithms = []
            for _, algorithm in iter(self.__sequence.items()):
                if type(algorithm) == SelectionAlgorithm:
                    selection_algorithms.append(algorithm)
                    s += "\"" + selection_algorithms.name() + "\", "
            if len(selection_algorithms):
                s = s[:-2]
            s += "]\n}\n"
            f = open(json_configuration_filename, "w")
            f.write(s)
            f.close()
            print("Generated JSON configuration file " +
                  json_configuration_filename)
        else:
            print(
                "The sequence contains errors. Please fix them and generate again."
            )

    def print_detail(self):
        s = "Sequence:\n"
        for _, i in iter(self.__sequence.items()):
            s += " " + repr(i) + "\n\n"
        s = s[:-2]
        print(s)

    def __repr__(self):
        s = "Sequence:\n"
        for i in self.__sequence:
            s += "  " + i + "\n"
        s = s[:-1]
        return s

    def __iter__(self):
        for _, algorithm in iter(self.__sequence.items()):
            yield algorithm

    def __getitem__(self, value):
        return self.__sequence[value]


def extend_sequence(sequence, *args):
    new_sequence = []
    for item in sequence:
        new_sequence.append(item)
    for item in args:
        new_sequence.append(item)
    return Sequence(new_sequence)


def compose_sequences(*args):
    new_sequence = []
    for sequence in args:
        for item in sequence:
            new_sequence.append(item)
    return Sequence(new_sequence)

