class Type():
  def __init__(self, vtype):
    if vtype == "uint" or vtype == "unsigned int" or vtype == "unsigned int32_t":
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


class HostAlgorithm():
  def __init__(self):
    pass


class DeviceAlgorithm():
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


class HostInput(HostParameter, InputParameter):
  def __init__(self, value, vtype):
    if value.__class__ == str:
      self.__name = value
    else:
      assert compatible_parameter_assignment(value.__class__, __class__)
      assert value.type() == Type(vtype)
      self.__name = value.name()
    self.__type = Type(vtype)

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = Type(value)

  def __repr__(self):
    return "HostInput(\"" + self.__name + "\", " + repr(self.__type) + ")"


class HostOutput(HostParameter, OutputParameter):
  def __init__(self, value, vtype):
    if value.__class__ == str:
      self.__name = value
    else:
      assert compatible_parameter_assignment(value.__class__, __class__)
      assert value.type() == Type(vtype)
      self.__name = value.name()
    self.__type = Type(vtype)

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = Type(value)

  def __repr__(self):
    return "HostOutput(\"" + self.__name + "\", " + repr(self.__type) + ")"


class DeviceInput(DeviceParameter, InputParameter):
  def __init__(self, value, vtype):
    if value.__class__ == str:
      self.__name = value
    else:
      assert compatible_parameter_assignment(value.__class__, __class__)
      assert value.type() == Type(vtype)
      self.__name = value.name()
    self.__type = Type(vtype)

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = Type(value)

  def __repr__(self):
    return "DeviceInput(\"" + self.__name + "\", " + repr(self.__type) + ")"


class DeviceOutput(DeviceParameter, OutputParameter):
  def __init__(self, value, vtype):
    if value.__class__ == str:
      self.__name = value
    else:
      assert compatible_parameter_assignment(value.__class__, __class__)
      assert value.type() == Type(vtype)
      self.__name = value.name()
    self.__type = Type(vtype)

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = Type(value)

  def __repr__(self):
    return "DeviceOutput(\"" + self.__name + "\", " + repr(self.__type) + ")"


def prefix(indentation_level, indent_by = 2):
  return "".join([" "] * indentation_level * indent_by)


class Sequence():
  def __init__(self, *args):
    self.sequence = [i for i in args]

  def validate(self):
    warnings = 0
    errors = 0

    # Check there are not two outputs with the same name
    output_names = {}
    for algorithm in self.sequence:
      for parameter_name, parameter in iter(algorithm.parameters().items()):
        if issubclass(parameter.__class__, OutputParameter):
          if parameter.name() in output_names:
            output_names[parameter.name()].append(algorithm.name())
          else:
            output_names[parameter.name()] = [algorithm.name()]

    for k, v in iter(output_names.items()):
      # Note: This is a warning, as the sequence atm contains this
      if len(v) > 1:
        print("Warning: OutputParameter \"" + k + "\" appears on algorithms: ", end="")
        i = 0
        for algorithm_name in v:
          i += 1
          print(algorithm_name, end="")
          if i != len(v):
            print(", ", end="")
        print()
        warnings += 1
    
    # Check the inputs of all algorithms
    output_parameters = {}
    for algorithm in self.sequence:
      for parameter_name, parameter in iter(algorithm.parameters().items()):
        if issubclass(parameter.__class__, InputParameter):
          # Check the input is not orphaned (ie. that there is a previous Output that generated it)
          if parameter.name() not in output_parameters:
            print("Error: Parameter " + repr(parameter) + " of algorithm " + algorithm.name() + \
              " is an InputParameter not provided by any previous OutputParameter.")
            errors += 1
        # Note: Whenever we enforce InputParameters to come from OutputParameters always,
        #       then we can move the following two if statements to be included in the 
        #       "if issubclass(parameter.__class__, InputParameter):".
        # Check that the input and output types correspond
        if parameter.name() in output_parameters and \
          output_parameters[parameter.name()]["parameter"].type() != parameter.type():
          print("Error: Type mismatch (" + repr(parameter.type()) + ", " + repr(output_parameters[parameter.name()]["parameter"].type()) + ") " \
            + "between " + algorithm.name() + "::" + repr(parameter) \
            + " and " + output_parameters[parameter.name()]["algorithm"].name() \
            + "::" + repr(output_parameters[parameter.name()]["parameter"]))
          errors += 1
        # Check the scope (Device, Host) of the input and output parameters matches
        if parameter.name() in output_parameters and \
          ((issubclass(parameter.__class__, DeviceParameter) and \
            issubclass(output_parameters[parameter.name()]["parameter"].__class__, HostParameter)) or \
          (issubclass(parameter.__class__, HostParameter) and \
            issubclass(output_parameters[parameter.name()]["parameter"].__class__, DeviceParameter))):
          print("Error: Scope mismatch (" + parameter.__class__ + ", " + output_parameters[parameter.name()]["parameter"].__class__ + ") " \
            + "of InputParameter " + repr(parameter) + " of algorithm " + algorithm.name())
          errors += 1
      for parameter_name, parameter in iter(algorithm.parameters().items()):
        if issubclass(parameter.__class__, OutputParameter):
          output_parameters[parameter.name()] = {"parameter": parameter, "algorithm": algorithm}

    if errors >= 1:
      print("Number of sequence errors:", errors)
      return False
    elif warnings >= 1:
      print("Number of sequence warnings:", warnings)

    return True

  def generate(self, output_filename = "ConfiguredSequence.h", prefix_includes = "../../"):
    # Check that sequence is valid
    print("Validating sequence...")
    if self.validate():
      print("Generating sequence file...")
      # Add all the includes
      s = "#pragma once\n\n#include <tuple>\n"
      for algorithm in self.sequence:
        s += "#include \"" + prefix_includes + algorithm.filename() + "\"\n"
      s += "\n"
      # Generate all parameters
      parameters = {}
      for algorithm in self.sequence:
        for parameter_t, parameter in iter(algorithm.parameters().items()):
          if parameter.name() in parameters:
            parameters[parameter.name()].append((algorithm.name(), algorithm.namespace(), parameter_t))
          else:
            parameters[parameter.name()] = [(algorithm.name(), algorithm.namespace(), parameter_t)]
      # Generate configuration
      for paramenter_name, v in iter(parameters.items()):
        s += "struct " + paramenter_name + " : "
        for algorithm_name, algorithm_namespace, parameter_t in v:
          s += algorithm_namespace + "::Parameters::" + parameter_t + ", "
        s = s[:-2]
        s += " { constexpr static auto name {\"" + paramenter_name + "\"}; size_t size; char* offset; };\n"
      # Generate sequence
      s += "\ntypedef std::tuple<\n"
      i_alg = 0
      for algorithm in self.sequence:
        i_alg += 1
        s += prefix(1) + algorithm.namespace() + "::" + algorithm.original_name() + "<std::tuple<"
        i = 0
        for parameter_t, parameter in iter(algorithm.parameters().items()):
          i += 1
          s += parameter.name()
          if i != len(algorithm.parameters()):
            s += ", "
        s += ">, "
        i = 0
        for c in algorithm.name():
          i += 1
          s += "'" + c + "'"
          if i != len(algorithm.name()):
            s += ", "
        s += ">"
        if i_alg != len(self.sequence):
          s += ","
        s += "\n"
      s += "> configured_sequence_t;\n"
      f = open(output_filename, "w")
      f.write(s)
      f.close()
      print("Generated sequence file " + output_filename)
    else:
      print("The sequence contains errors. Please fix them and generate again.")  

  def print_detail(self):
    s = "Sequence:\n"
    for i in self.sequence:
      s += " " + repr(i) + "\n\n"
    s = s[:-2]
    print(s)

  def extend_sequence(self, *args):
    for algorithm in args:
      self.sequence.append(algorithm)

  def __repr__(self):
    s = "Sequence:\n"
    for i in self.sequence:
      s += "  " + i.name() + "\n"
    s = s[:-1]
    return s