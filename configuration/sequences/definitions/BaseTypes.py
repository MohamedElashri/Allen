from collections import OrderedDict


class Line():
    def __init__(self):
        pass


class SpecialLine(Line):
    def __init__(self):
        pass


class VeloLine(Line):
    def __init__(self):
        pass


class OneTrackLine(Line):
    def __init__(self):
        pass


class TwoTrackLine(Line):
    def __init__(self):
        pass


class VeloUTTwoTrackLine(Line):
    def __init__(self):
        pass


class Type():
    def __init__(self, vtype):
        if vtype.__class__ == Type:
            self.__type = vtype.type()
        elif vtype == "uint" or vtype == "unsigned int" or vtype == "unsigned int32_t":
            self.__type = "uint32_t"
        elif vtype == "int" or vtype == "signed int":
            self.__type = "int32_t"
        elif vtype == "unsigned short" or vtype == "unsigned int16_t":
            self.__type = "uint16_t"
        elif vtype == "short" or vtype == "signed short":
            self.__type = "int16_t"
        elif vtype == "unsigned char":
            self.__type = "uint8_t"
        elif vtype == "signed char":
            self.__type = "int8_t"
        else:
            self.__type = vtype

    def type(self):
        return self.__type

    def __eq__(self, other):
        return self.type() == other.type()

    def __ne__(self, other):
        return self.type() != other.type()

    def __repr__(self):
        return self.__type

    def __str__(self):
        return self.__type


class Algorithm():
    def __init__(self):
        pass


class HostAlgorithm(Algorithm):
    def __init__(self):
        pass


class DeviceAlgorithm(Algorithm):
    def __init__(self):
        pass


class HostParameter():
    def __init__(self):
        pass


class DeviceParameter():
    def __init__(self):
        pass


class InputParameter():
    def __init__(self):
        pass


class OutputParameter():
    def __init__(self):
        pass


def compatible_parameter_assignment(a, b):
    """Returns whether the parameter b can accept to be written
    with class a."""
    return ((issubclass(b, DeviceParameter) and issubclass(a, DeviceParameter)) or \
      (issubclass(b, HostParameter) and issubclass(a, HostParameter))) and \
      (issubclass(b, InputParameter) or (issubclass(b, OutputParameter) and issubclass(a, OutputParameter)))


def check_input_parameter(parameter, assign_class, typename):
    assert compatible_parameter_assignment(parameter.__class__, assign_class)
    assert parameter.type() == Type(typename)
    return assign_class(parameter.name(), parameter.type(), parameter.producer())


class HostInput(HostParameter, InputParameter):
    def __init__(self, name, typename, producer):
        self.__name = name
        self.__type = Type(typename)
        self.__producer = producer

    def name(self):
        return self.__name

    def type(self):
        return self.__type

    def producer(self):
        return self.__producer

    def fullname(self):
        return self.__producer + "__" + self.__name

    def __repr__(self):
        return "HostInput(\"" + self.__name + "\", " + repr(self.__type) + ", " + self.__producer + ")"


class HostOutput(HostParameter, OutputParameter):
    def __init__(self, name, typename, producer):
        self.__name = name
        self.__type = Type(typename)
        self.__producer = producer

    def name(self):
        return self.__name

    def type(self):
        return self.__type

    def producer(self):
        return self.__producer

    def fullname(self):
        return self.__producer + "__" + self.__name

    def __repr__(self):
        return "HostOutput(\"" + self.__name + "\", " + repr(self.__type) + ", " + self.__producer + ")"


class DeviceInput(DeviceParameter, InputParameter):
    def __init__(self, name, typename, producer):
        self.__name = name
        self.__type = Type(typename)
        self.__producer = producer

    def name(self):
        return self.__name

    def type(self):
        return self.__type

    def producer(self):
        return self.__producer

    def fullname(self):
        return self.__producer + "__" + self.__name

    def __repr__(self):
        return "DeviceInput(\"" + self.__name + "\", " + repr(self.__type) + ", " + self.__producer + ")"


class DeviceOutput(DeviceParameter, OutputParameter):
    def __init__(self, name, typename, producer):
        self.__name = name
        self.__type = Type(typename)
        self.__producer = producer

    def name(self):
        return self.__name

    def type(self):
        return self.__type

    def producer(self):
        return self.__producer

    def fullname(self):
        return self.__producer + "__" + self.__name

    def __repr__(self):
        return "DeviceOutput(\"" + self.__name + "\", " + repr(self.__type) + ", " + self.__producer + ")"


class Property():
    def __init__(self, vtype, default_value, description, value=""):
        self.__type = Type(vtype)
        self.__default_value = default_value
        self.__description = description
        if type(value) == str:
            self.__value = value
        elif type(value) == Property:
            self.__value = value.value()
        else:
            self.__value = ""

    def type(self):
        return self.__type

    def value(self):
        return self.__value

    def default_value(self):
        return self.__default_value

    def description(self):
        return self.__description

    def set_value(self, value):
        self.__value = value

    def __repr__(self):
        return "Property(" + repr(
            self.__type
        ) + ", " + self.__default_value + ", " + self.__description + ") = \"" + self.__value + "\""


def prefix(indentation_level, indent_by=2):
    return "".join([" "] * indentation_level * indent_by)


class Sequence():
    def __init__(self, *args):
        self.__sequence = OrderedDict()
        self.__lines = OrderedDict()
        if type(args[0]) == list:
            for item in args[0]:
                if issubclass(type(item), Algorithm):
                    self.__sequence[item.name()] = item
                elif issubclass(type(item), Line):
                    self.__lines[item.name()] = item
        else:
            for item in args:
                if issubclass(type(item), Algorithm):
                    self.__sequence[item.name()] = item
                elif issubclass(type(item), Line):
                    self.__lines[item.name()] = item

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
                        output_names[parameter.fullname()].append(algorithm.name())
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
            for parameter_name, parameter in iter(
                    algorithm.parameters().items()):
                if issubclass(type(parameter), InputParameter):
                    # Check the input is not orphaned (ie. that there is a previous Output that generated it)
                    if parameter.fullname() not in output_parameters:
                        print("Error: Parameter " + repr(parameter) + " of algorithm " + algorithm.name() + \
                          " is an InputParameter not provided by any previous OutputParameter.")
                        errors += 1
                # Note: Whenever we enforce InputParameters to come from OutputParameters always,
                #       then we can move the following two if statements to be included in the
                #       "if issubclass(type(parameter), InputParameter):".
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
                 json_configuration_filename="Sequence.json",
                 prefix_includes="../../"):
        # Check that sequence is valid
        print("Validating sequence...")
        if self.validate():
            print("Generating sequence file...")
            # Add all the includes
            s = "#pragma once\n\n#include <tuple>\n"
            s += "#include \"" + prefix_includes + "device/selections/Hlt1/include/LineTraverser.cuh\"\n"
            for _, algorithm in iter(self.__sequence.items()):
                s += "#include \"" + prefix_includes + algorithm.filename(
                ) + "\"\n"
            for _, line in iter(self.__lines.items()):
                s += "#include \"" + prefix_includes + line.filename() + "\"\n"
            s += "\n"
            # Generate all parameters
            parameters = OrderedDict([])
            for _, algorithm in iter(self.__sequence.items()):
                for parameter_t, parameter in iter(
                        algorithm.parameters().items()):
                    if parameter.fullname() in parameters:
                        parameters[parameter.fullname()].append(
                            (algorithm.name(), algorithm.namespace(),
                             parameter_t))
                    else:
                        parameters[parameter.fullname()] = [(algorithm.name(),
                                                         algorithm.namespace(),
                                                         parameter_t)]
            # Generate configuration
            for paramenter_name, v in iter(parameters.items()):
                s += "struct " + paramenter_name + " : "
                inheriting_classes = []
                for algorithm_name, algorithm_namespace, parameter_t in v:
                    parameter = algorithm_namespace + "::Parameters::" + parameter_t
                    if parameter not in inheriting_classes:
                        inheriting_classes.append(parameter)
                for inheriting_class in inheriting_classes:
                    s += inheriting_class + ", "
                s = s[:-2]
                s += " { constexpr static auto name {\"" + paramenter_name + "\"}; size_t size; char* offset; };\n"
            # Generate lines
            s += "\nusing configured_lines_t = std::tuple<"
            for _, line in iter(self.__lines.items()):
                s += line.namespace() + "::" + line.name() + ", "
            if len(self.__lines) > 0:
                s = s[:-2]
            s += ">;\n"
            # Generate sequence
            s += "\nusing configured_sequence_t = std::tuple<\n"
            i_alg = 0
            for _, algorithm in iter(self.__sequence.items()):
                i_alg += 1
                # Add algorithm namespace::name
                s += prefix(1) + algorithm.namespace(
                ) + "::" + algorithm.original_name() + "<std::tuple<"
                i = 0
                # Add parameters
                for parameter_t, parameter in iter(
                        algorithm.parameters().items()):
                    i += 1
                    s += parameter.fullname()
                    if i != len(algorithm.parameters()):
                        s += ", "
                s += ">, "
                i = 0
                # In case it is needed, pass the lines as an argument to the template
                if algorithm.requires_lines():
                    s += "configured_lines_t, "
                # Add name
                for c in algorithm.name():
                    i += 1
                    s += "'" + c + "'"
                    if i != len(algorithm.name()):
                        s += ", "
                s += ">"
                if i_alg != len(self.__sequence):
                    s += ","
                s += "\n"
            s += ">;\n"
            f = open(output_filename, "w")
            f.write(s)
            f.close()
            print("Generated sequence file " + output_filename)
            print("Generating JSON configuration file...")
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
            for _, line in iter(self.__lines.items()):
                s += "\"" + line.namespace() + "\", "
            if len(self.__lines) > 0:
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
        for _, line in iter(self.__lines.items()):
            yield line

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


class AlgorithmRepr(type):
    def __repr__(cls):
        return "class " + cls.__class__.__name__ + " : " + cls.__bases__[0].__name__ + "\n inputs: " + \
            str(cls.inputs) + "\n outputs: " + str(cls.outputs) + "\n properties: " + str(cls.props) + "\n"
        # return f"class {type(cls)} : {cls.__bases__[0].__name__}\n inputs: {cls.inputs}\n outputs: {cls.outputs}\n properties: {cls.props}\n"
