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


class HostInput(HostParameter, InputParameter):
  def __init__(self, name, vtype):
    self.__name = name
    self.__type = vtype

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = value

  def __repr__(self):
    return "HostInput(\"" + self.__name + "\", " + self.__type + ")"


class HostOutput(HostParameter, OutputParameter):
  def __init__(self, name, vtype):
    self.__name = name
    self.__type = vtype

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = value

  def __repr__(self):
    return "HostOutput(\"" + self.__name + "\", " + self.__type + ")"


class DeviceInput(DeviceParameter, InputParameter):
  def __init__(self, name, vtype):
    self.__name = name
    self.__type = vtype

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = value

  def __repr__(self):
    return "DeviceInput(\"" + self.__name + "\", " + self.__type + ")"


class DeviceOutput(DeviceParameter, OutputParameter):
  def __init__(self, name, vtype):
    self.__name = name
    self.__type = vtype

  def name(self):
    return self.__name

  def type(self):
    return self.__type

  def set_name(self, value):
    self.__name = value

  def set_type(self, value):
    self.__type = value

  def __repr__(self):
    return "DeviceOutput(\"" + self.__name + "\", " + self.__type + ")"


def compatible_parameter_assignment(a, b):
  """Returns whether the parameter b can accept to be written
  with class a."""
  return ((issubclass(b, DeviceParameter) and issubclass(a, DeviceParameter)) or \
    (issubclass(b, HostParameter) and issubclass(a, HostParameter))) and \
    (issubclass(b, InputParameter) or (issubclass(b, OutputParameter) and issubclass(a, OutputParameter)))


class Sequence():
  def __init__(self, *args):
    self.sequence = [i for i in args]

  def validate(self):
    warnings = 0
    errors = 0

    # Check there are not two outputs with the same name
    output_names = {}
    for algorithm in self.sequence:
      for parameter in algorithm.parameters():
        if issubclass(parameter.__class__, OutputParameter):
          if parameter.name() in output_names:
            output_names[parameter.name()].append(algorithm.name())
          else:
            output_names[parameter.name()] = [algorithm.name()]

    for k, v in iter(output_names.items()):
      # Note: This is a warning, as the sequence atm contains this
      if len(v) > 1:
        print("Warning: Parameter \"" + k + "\" appears on algorithms ", end="")
        for algorithm_name in v:
          print(v + " ", end="")
        print()
        warnings += 1
    
    # Check the inputs of all algorithms
    output_parameters = {}
    for algorithm in self.sequence:
      for parameter in algorithm.parameters():
        if issubclass(parameter.__class__, InputParameter):
          # Check the input is not orphaned (ie. that there is a previous Output that generated it)
          if parameter.name() not in output_parameters:
            print("Error: Parameter " + repr(parameter) + " of algorithm " + algorithm.name() + \
              " is an InputParameter not provided by any previous OutputParameter.")
            errors += 1
          # Check that the input and output types correspond
          if parameter.name() in output_parameters and \
            output_parameters[parameter.name()].type() != parameter.type():
            print("Error: Type mismatch (" + parameter.type() + ", " + output_parameters[parameter.name()].type() + ") " \
              + "of InputParameter " + repr(parameter) + " of algorithm " + algorithm.name())
            errors += 1
          # Check the scope (Device, Host) of the input and output parameters matches
          if parameter.name() in output_parameters and \
            ((issubclass(parameter.__class__, DeviceParameter) and \
              issubclass(output_parameters[parameter.name()].__class__, HostParameter)) or \
            (issubclass(parameter.__class__, HostParameter) and \
              issubclass(output_parameters[parameter.name()].__class__, DeviceParameter))):
            print("Error: Scope mismatch (" + parameter.__class__ + ", " + output_parameters[parameter.name()].__class__ + ") " \
              + "of InputParameter " + repr(parameter) + " of algorithm " + algorithm.name())
            errors += 1
      for parameter in algorithm.parameters():
        if issubclass(parameter.__class__, OutputParameter):
          output_parameters[parameter.name()] = parameter

    if errors >= 1:
      return False
    elif warnings >= 1:
      print("Number of sequence warnings:", wanings)

    return True

  def generate(self):
    # Check that sequence is valid
    print("Validating sequence...")
    if self.validate():
      print("Generating sequence file...")

    else:
      print("The sequence contains errors. Please fix them and generate again.")  

  def __repr__(self):
    s = "Sequence:\n"
    for i in self.sequence:
      s += " " + repr(i) + "\n"
    return s