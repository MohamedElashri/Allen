###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
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
        elif vtype == "unsigned" or vtype == "unsigned int" or vtype == "unsigned int32_t":
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


class SelectionAlgorithm(Algorithm):
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
    if typename == "int" or parameter.type() == Type("int"):
        # If the type is int, unfortunately it is not possible to distinguish whether
        # the parser parsed an unknown type or not, so just accept it
        return assign_class(parameter.name(), parameter.type(),
                            parameter.producer())
    else:
        assert compatible_parameter_assignment(type(parameter), assign_class)
        assert parameter.type() == Type(typename)
        return assign_class(parameter.name(), parameter.type(),
                            parameter.producer())


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
        return "HostInput(\"" + self.__name + "\", " + repr(
            self.__type) + ", " + self.__producer + ")"


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
        return "HostOutput(\"" + self.__name + "\", " + repr(
            self.__type) + ", " + self.__producer + ")"


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
        return "DeviceInput(\"" + self.__name + "\", " + repr(
            self.__type) + ", " + self.__producer + ")"


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
        return "DeviceOutput(\"" + self.__name + "\", " + repr(
            self.__type) + ", " + self.__producer + ")"


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


def parameter_tuple(parameter):
    if type(parameter) == tuple:
        return parameter
    return (parameter, )


class AlgorithmRepr(type):
    def __repr__(cls):
        return "class " + cls.__class__.__name__ + " : " + cls.__bases__[0].__name__ + "\n inputs: " + \
            str(cls.inputs) + "\n outputs: " + str(cls.outputs) + "\n properties: " + str(cls.props) + "\n"
