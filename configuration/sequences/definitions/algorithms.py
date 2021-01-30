###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from collections import OrderedDict


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


class ValidationAlgorithm(Algorithm):
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

class pv_beamline_calculate_denom_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_pvtracks_t",
    "dev_zpeaks_t",
    "dev_number_of_zpeaks_t",)
  outputs = (
    "dev_pvtracks_denom_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "pv_beamline_calculate_denom"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_pvtracks_t,
    dev_zpeaks_t,
    dev_number_of_zpeaks_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_beamline_calculate_denom_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_calculate_denom.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_calculate_denom_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_pvtracks_t", check_input_parameter(dev_pvtracks_t, DeviceInput, "PVTrack")),
      ("dev_zpeaks_t", check_input_parameter(dev_zpeaks_t, DeviceInput, "float")),
      ("dev_number_of_zpeaks_t", check_input_parameter(dev_number_of_zpeaks_t, DeviceInput, "unsigned int")),
      ("dev_pvtracks_denom_t", DeviceOutput("dev_pvtracks_denom_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_pvtracks_t(self):
    return self.__ordered_parameters["dev_pvtracks_t"]

  def dev_zpeaks_t(self):
    return self.__ordered_parameters["dev_zpeaks_t"]

  def dev_number_of_zpeaks_t(self):
    return self.__ordered_parameters["dev_number_of_zpeaks_t"]

  def dev_pvtracks_denom_t(self):
    return self.__ordered_parameters["dev_pvtracks_denom_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_beamline_cleanup_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_multi_fit_vertices_t",
    "dev_number_of_multi_fit_vertices_t",)
  outputs = (
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "pv_beamline_cleanup"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_multi_fit_vertices_t,
    dev_number_of_multi_fit_vertices_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_beamline_cleanup_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_cleanup.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_cleanup_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_multi_fit_vertices_t", check_input_parameter(dev_multi_fit_vertices_t, DeviceInput, "PV::Vertex")),
      ("dev_number_of_multi_fit_vertices_t", check_input_parameter(dev_number_of_multi_fit_vertices_t, DeviceInput, "unsigned int")),
      ("dev_multi_final_vertices_t", DeviceOutput("dev_multi_final_vertices_t", "PV::Vertex", self.__name)),
      ("dev_number_of_multi_final_vertices_t", DeviceOutput("dev_number_of_multi_final_vertices_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_multi_fit_vertices_t(self):
    return self.__ordered_parameters["dev_multi_fit_vertices_t"]

  def dev_number_of_multi_fit_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_fit_vertices_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_beamline_extrapolate_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_reconstructed_velo_tracks_t",
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",)
  outputs = (
    "dev_pvtracks_t",
    "dev_pvtrack_z_t",
    "dev_pvtrack_unsorted_z_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "pv_beamline_extrapolate"

  def __init__(self,
    host_number_of_reconstructed_velo_tracks_t,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_velo_kalman_beamline_states_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_beamline_extrapolate_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_extrapolate.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_extrapolate_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_pvtracks_t", DeviceOutput("dev_pvtracks_t", "PVTrack", self.__name)),
      ("dev_pvtrack_z_t", DeviceOutput("dev_pvtrack_z_t", "float", self.__name)),
      ("dev_pvtrack_unsorted_z_t", DeviceOutput("dev_pvtrack_unsorted_z_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_pvtracks_t(self):
    return self.__ordered_parameters["dev_pvtracks_t"]

  def dev_pvtrack_z_t(self):
    return self.__ordered_parameters["dev_pvtrack_z_t"]

  def dev_pvtrack_unsorted_z_t(self):
    return self.__ordered_parameters["dev_pvtrack_unsorted_z_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_beamline_histo_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_pvtracks_t",)
  outputs = (
    "dev_zhisto_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "pv_beamline_histo"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_pvtracks_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_beamline_histo_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_histo.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_histo_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_pvtracks_t", check_input_parameter(dev_pvtracks_t, DeviceInput, "PVTrack")),
      ("dev_zhisto_t", DeviceOutput("dev_zhisto_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_pvtracks_t(self):
    return self.__ordered_parameters["dev_pvtracks_t"]

  def dev_zhisto_t(self):
    return self.__ordered_parameters["dev_zhisto_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_beamline_multi_fitter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_pvtracks_t",
    "dev_pvtracks_denom_t",
    "dev_zpeaks_t",
    "dev_number_of_zpeaks_t",
    "dev_pvtrack_z_t",)
  outputs = (
    "dev_multi_fit_vertices_t",
    "dev_number_of_multi_fit_vertices_t",)
  props = (
    "verbosity",
    "block_dim_y",)
  aggregates = ()
  namespace = "pv_beamline_multi_fitter"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_pvtracks_t,
    dev_pvtracks_denom_t,
    dev_zpeaks_t,
    dev_number_of_zpeaks_t,
    dev_pvtrack_z_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_y=Property("unsigned int", "", "block dimension Y"),
    name="pv_beamline_multi_fitter_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_multi_fitter.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_multi_fitter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_pvtracks_t", check_input_parameter(dev_pvtracks_t, DeviceInput, "PVTrack")),
      ("dev_pvtracks_denom_t", check_input_parameter(dev_pvtracks_denom_t, DeviceInput, "float")),
      ("dev_zpeaks_t", check_input_parameter(dev_zpeaks_t, DeviceInput, "float")),
      ("dev_number_of_zpeaks_t", check_input_parameter(dev_number_of_zpeaks_t, DeviceInput, "unsigned int")),
      ("dev_pvtrack_z_t", check_input_parameter(dev_pvtrack_z_t, DeviceInput, "float")),
      ("dev_multi_fit_vertices_t", DeviceOutput("dev_multi_fit_vertices_t", "PV::Vertex", self.__name)),
      ("dev_number_of_multi_fit_vertices_t", DeviceOutput("dev_number_of_multi_fit_vertices_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_y", Property("unsigned int", "", "block dimension Y", block_dim_y))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_pvtracks_t(self):
    return self.__ordered_parameters["dev_pvtracks_t"]

  def dev_pvtracks_denom_t(self):
    return self.__ordered_parameters["dev_pvtracks_denom_t"]

  def dev_zpeaks_t(self):
    return self.__ordered_parameters["dev_zpeaks_t"]

  def dev_number_of_zpeaks_t(self):
    return self.__ordered_parameters["dev_number_of_zpeaks_t"]

  def dev_pvtrack_z_t(self):
    return self.__ordered_parameters["dev_pvtrack_z_t"]

  def dev_multi_fit_vertices_t(self):
    return self.__ordered_parameters["dev_multi_fit_vertices_t"]

  def dev_number_of_multi_fit_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_fit_vertices_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_y(self):
    return self.__ordered_properties["block_dim_y"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_beamline_peak_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_zhisto_t",)
  outputs = (
    "dev_zpeaks_t",
    "dev_number_of_zpeaks_t",)
  props = (
    "verbosity",
    "block_dim_x",)
  aggregates = ()
  namespace = "pv_beamline_peak"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_zhisto_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension X"),
    name="pv_beamline_peak_t"):
    self.__filename = "device/PV/beamlinePV/include/pv_beamline_peak.cuh"
    self.__name = name
    self.__original_name = "pv_beamline_peak_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_zhisto_t", check_input_parameter(dev_zhisto_t, DeviceInput, "float")),
      ("dev_zpeaks_t", DeviceOutput("dev_zpeaks_t", "float", self.__name)),
      ("dev_number_of_zpeaks_t", DeviceOutput("dev_number_of_zpeaks_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension X", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_zhisto_t(self):
    return self.__ordered_parameters["dev_zhisto_t"]

  def dev_zpeaks_t(self):
    return self.__ordered_parameters["dev_zpeaks_t"]

  def dev_number_of_zpeaks_t(self):
    return self.__ordered_parameters["dev_number_of_zpeaks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_fit_seeds_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_seeds_t",
    "dev_number_seeds_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_atomics_velo_t",
    "dev_velo_track_hit_number_t",)
  outputs = (
    "dev_vertex_t",
    "dev_number_vertex_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "fit_seeds"

  def __init__(self,
    host_number_of_events_t,
    dev_seeds_t,
    dev_number_seeds_t,
    dev_velo_kalman_beamline_states_t,
    dev_atomics_velo_t,
    dev_velo_track_hit_number_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_fit_seeds_t"):
    self.__filename = "device/PV/patPV/include/FitSeeds.cuh"
    self.__name = name
    self.__original_name = "pv_fit_seeds_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_vertex_t", DeviceOutput("dev_vertex_t", "int", self.__name)),
      ("dev_number_vertex_t", DeviceOutput("dev_number_vertex_t", "int", self.__name)),
      ("dev_seeds_t", check_input_parameter(dev_seeds_t, DeviceInput, "int")),
      ("dev_number_seeds_t", check_input_parameter(dev_number_seeds_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_atomics_velo_t", check_input_parameter(dev_atomics_velo_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hit_number_t", check_input_parameter(dev_velo_track_hit_number_t, DeviceInput, "unsigned int"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_vertex_t(self):
    return self.__ordered_parameters["dev_vertex_t"]

  def dev_number_vertex_t(self):
    return self.__ordered_parameters["dev_number_vertex_t"]

  def dev_seeds_t(self):
    return self.__ordered_parameters["dev_seeds_t"]

  def dev_number_seeds_t(self):
    return self.__ordered_parameters["dev_number_seeds_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_velo_track_hit_number_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class pv_get_seeds_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_atomics_velo_t",
    "dev_velo_track_hit_number_t",)
  outputs = (
    "dev_seeds_t",
    "dev_number_seeds_t",)
  props = (
    "verbosity",
    "max_chi2_merge",
    "factor_to_increase_errors",
    "min_cluster_mult",
    "min_close_tracks_in_cluster",
    "dz_close_tracks_in_cluster",
    "high_mult",
    "ratio_sig2_high_mult",
    "ratio_sig2_low_mult",
    "block_dim",)
  aggregates = ()
  namespace = "pv_get_seeds"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_velo_kalman_beamline_states_t,
    dev_atomics_velo_t,
    dev_velo_track_hit_number_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    max_chi2_merge=Property("float", "", "max chi2 merge"),
    factor_to_increase_errors=Property("float", "", "factor to increase errors"),
    min_cluster_mult=Property("int", "", "min cluster mult"),
    min_close_tracks_in_cluster=Property("int", "", "min close tracks in cluster"),
    dz_close_tracks_in_cluster=Property("float", "", "dz close tracks in cluster [mm]"),
    high_mult=Property("int", "", "high mult"),
    ratio_sig2_high_mult=Property("float", "", "ratio sig2 high mult"),
    ratio_sig2_low_mult=Property("float", "", "ratio sig2 low mult"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="pv_get_seeds_t"):
    self.__filename = "device/PV/patPV/include/GetSeeds.cuh"
    self.__name = name
    self.__original_name = "pv_get_seeds_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_atomics_velo_t", check_input_parameter(dev_atomics_velo_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hit_number_t", check_input_parameter(dev_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_seeds_t", DeviceOutput("dev_seeds_t", "int", self.__name)),
      ("dev_number_seeds_t", DeviceOutput("dev_number_seeds_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("max_chi2_merge", Property("float", "", "max chi2 merge", max_chi2_merge)),
      ("factor_to_increase_errors", Property("float", "", "factor to increase errors", factor_to_increase_errors)),
      ("min_cluster_mult", Property("int", "", "min cluster mult", min_cluster_mult)),
      ("min_close_tracks_in_cluster", Property("int", "", "min close tracks in cluster", min_close_tracks_in_cluster)),
      ("dz_close_tracks_in_cluster", Property("float", "", "dz close tracks in cluster [mm]", dz_close_tracks_in_cluster)),
      ("high_mult", Property("int", "", "high mult", high_mult)),
      ("ratio_sig2_high_mult", Property("float", "", "ratio sig2 high mult", ratio_sig2_high_mult)),
      ("ratio_sig2_low_mult", Property("float", "", "ratio sig2 low mult", ratio_sig2_low_mult)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_velo_track_hit_number_t"]

  def dev_seeds_t(self):
    return self.__ordered_parameters["dev_seeds_t"]

  def dev_number_seeds_t(self):
    return self.__ordered_parameters["dev_number_seeds_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def max_chi2_merge(self):
    return self.__ordered_properties["max_chi2_merge"]

  def factor_to_increase_errors(self):
    return self.__ordered_properties["factor_to_increase_errors"]

  def min_cluster_mult(self):
    return self.__ordered_properties["min_cluster_mult"]

  def min_close_tracks_in_cluster(self):
    return self.__ordered_properties["min_close_tracks_in_cluster"]

  def dz_close_tracks_in_cluster(self):
    return self.__ordered_properties["dz_close_tracks_in_cluster"]

  def high_mult(self):
    return self.__ordered_properties["high_mult"]

  def ratio_sig2_high_mult(self):
    return self.__ordered_properties["ratio_sig2_high_mult"]

  def ratio_sig2_low_mult(self):
    return self.__ordered_properties["ratio_sig2_low_mult"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_consolidate_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_hits_in_scifi_tracks_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_offsets_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_scifi_tracks_t",
    "dev_scifi_lf_parametrization_consolidate_t",)
  outputs = (
    "dev_scifi_track_hits_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "scifi_consolidate_tracks"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_hits_in_scifi_tracks_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_scifi_hits_t,
    dev_scifi_hit_offsets_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_scifi_tracks_t,
    dev_scifi_lf_parametrization_consolidate_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="scifi_consolidate_tracks_t"):
    self.__filename = "device/SciFi/consolidate/include/ConsolidateSciFi.cuh"
    self.__name = name
    self.__original_name = "scifi_consolidate_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_hits_in_scifi_tracks_t", check_input_parameter(host_accumulated_number_of_hits_in_scifi_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_scifi_tracks_t", check_input_parameter(dev_scifi_tracks_t, DeviceInput, "int")),
      ("dev_scifi_lf_parametrization_consolidate_t", check_input_parameter(dev_scifi_lf_parametrization_consolidate_t, DeviceInput, "float")),
      ("dev_scifi_track_hits_t", DeviceOutput("dev_scifi_track_hits_t", "char", self.__name)),
      ("dev_scifi_qop_t", DeviceOutput("dev_scifi_qop_t", "float", self.__name)),
      ("dev_scifi_states_t", DeviceOutput("dev_scifi_states_t", "int", self.__name)),
      ("dev_scifi_track_ut_indices_t", DeviceOutput("dev_scifi_track_ut_indices_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_hits_in_scifi_tracks_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_hits_in_scifi_tracks_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_scifi_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_tracks_t"]

  def dev_scifi_lf_parametrization_consolidate_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_consolidate_t"]

  def dev_scifi_track_hits_t(self):
    return self.__ordered_parameters["dev_scifi_track_hits_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_copy_track_hit_number_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_offsets_ut_tracks_t",
    "dev_scifi_tracks_t",
    "dev_offsets_forward_tracks_t",)
  outputs = (
    "dev_scifi_track_hit_number_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "scifi_copy_track_hit_number"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_offsets_ut_tracks_t,
    dev_scifi_tracks_t,
    dev_offsets_forward_tracks_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="scifi_copy_track_hit_number_t"):
    self.__filename = "device/SciFi/consolidate/include/SciFiCopyTrackHitNumber.cuh"
    self.__name = name
    self.__original_name = "scifi_copy_track_hit_number_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_scifi_tracks_t", check_input_parameter(dev_scifi_tracks_t, DeviceInput, "int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hit_number_t", DeviceOutput("dev_scifi_track_hit_number_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_scifi_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_tracks_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_scifi_track_hit_number_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_create_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_scifi_lf_initial_windows_t",
    "dev_scifi_lf_process_track_t",
    "dev_scifi_lf_found_triplets_t",
    "dev_scifi_lf_number_of_found_triplets_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_offsets_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "dev_ut_states_t",)
  outputs = (
    "dev_scifi_lf_tracks_t",
    "dev_scifi_lf_atomics_t",
    "dev_scifi_lf_total_number_of_found_triplets_t",
    "dev_scifi_lf_parametrization_t",)
  props = (
    "verbosity",
    "triplet_keep_best_block_dim",
    "calculate_parametrization_block_dim",
    "extend_tracks_block_dim",)
  aggregates = ()
  namespace = "lf_create_tracks"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_scifi_lf_initial_windows_t,
    dev_scifi_lf_process_track_t,
    dev_scifi_lf_found_triplets_t,
    dev_scifi_lf_number_of_found_triplets_t,
    dev_scifi_hits_t,
    dev_scifi_hit_offsets_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    dev_ut_states_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    triplet_keep_best_block_dim=Property("DeviceDimensions", "", "block dimensions triplet keep best"),
    calculate_parametrization_block_dim=Property("DeviceDimensions", "", "block dimensions calculate parametrization"),
    extend_tracks_block_dim=Property("DeviceDimensions", "", "block dimensions extend tracks"),
    name="lf_create_tracks_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFCreateTracks.cuh"
    self.__name = name
    self.__original_name = "lf_create_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_initial_windows_t", check_input_parameter(dev_scifi_lf_initial_windows_t, DeviceInput, "int")),
      ("dev_scifi_lf_process_track_t", check_input_parameter(dev_scifi_lf_process_track_t, DeviceInput, "bool")),
      ("dev_scifi_lf_found_triplets_t", check_input_parameter(dev_scifi_lf_found_triplets_t, DeviceInput, "int")),
      ("dev_scifi_lf_number_of_found_triplets_t", check_input_parameter(dev_scifi_lf_number_of_found_triplets_t, DeviceInput, "int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_states_t", check_input_parameter(dev_ut_states_t, DeviceInput, "int")),
      ("dev_scifi_lf_tracks_t", DeviceOutput("dev_scifi_lf_tracks_t", "int", self.__name)),
      ("dev_scifi_lf_atomics_t", DeviceOutput("dev_scifi_lf_atomics_t", "unsigned int", self.__name)),
      ("dev_scifi_lf_total_number_of_found_triplets_t", DeviceOutput("dev_scifi_lf_total_number_of_found_triplets_t", "unsigned int", self.__name)),
      ("dev_scifi_lf_parametrization_t", DeviceOutput("dev_scifi_lf_parametrization_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("triplet_keep_best_block_dim", Property("DeviceDimensions", "", "block dimensions triplet keep best", triplet_keep_best_block_dim)),
      ("calculate_parametrization_block_dim", Property("DeviceDimensions", "", "block dimensions calculate parametrization", calculate_parametrization_block_dim)),
      ("extend_tracks_block_dim", Property("DeviceDimensions", "", "block dimensions extend tracks", extend_tracks_block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_scifi_lf_initial_windows_t(self):
    return self.__ordered_parameters["dev_scifi_lf_initial_windows_t"]

  def dev_scifi_lf_process_track_t(self):
    return self.__ordered_parameters["dev_scifi_lf_process_track_t"]

  def dev_scifi_lf_found_triplets_t(self):
    return self.__ordered_parameters["dev_scifi_lf_found_triplets_t"]

  def dev_scifi_lf_number_of_found_triplets_t(self):
    return self.__ordered_parameters["dev_scifi_lf_number_of_found_triplets_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_states_t(self):
    return self.__ordered_parameters["dev_ut_states_t"]

  def dev_scifi_lf_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_lf_tracks_t"]

  def dev_scifi_lf_atomics_t(self):
    return self.__ordered_parameters["dev_scifi_lf_atomics_t"]

  def dev_scifi_lf_total_number_of_found_triplets_t(self):
    return self.__ordered_parameters["dev_scifi_lf_total_number_of_found_triplets_t"]

  def dev_scifi_lf_parametrization_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def triplet_keep_best_block_dim(self):
    return self.__ordered_properties["triplet_keep_best_block_dim"]

  def calculate_parametrization_block_dim(self):
    return self.__ordered_properties["calculate_parametrization_block_dim"]

  def extend_tracks_block_dim(self):
    return self.__ordered_properties["extend_tracks_block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_least_mean_square_fit_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_count_t",
    "dev_atomics_ut_t",
    "dev_atomics_scifi_t",)
  outputs = (
    "dev_scifi_tracks_t",
    "dev_scifi_lf_parametrization_x_filter_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "lf_least_mean_square_fit"

  def __init__(self,
    host_number_of_events_t,
    dev_scifi_hits_t,
    dev_scifi_hit_count_t,
    dev_atomics_ut_t,
    dev_atomics_scifi_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="lf_least_mean_square_fit_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFLeastMeanSquareFit.cuh"
    self.__name = name
    self.__original_name = "lf_least_mean_square_fit_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_count_t", check_input_parameter(dev_scifi_hit_count_t, DeviceInput, "unsigned int")),
      ("dev_atomics_ut_t", check_input_parameter(dev_atomics_ut_t, DeviceInput, "unsigned int")),
      ("dev_scifi_tracks_t", DeviceOutput("dev_scifi_tracks_t", "int", self.__name)),
      ("dev_atomics_scifi_t", check_input_parameter(dev_atomics_scifi_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_parametrization_x_filter_t", DeviceOutput("dev_scifi_lf_parametrization_x_filter_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_count_t(self):
    return self.__ordered_parameters["dev_scifi_hit_count_t"]

  def dev_atomics_ut_t(self):
    return self.__ordered_parameters["dev_atomics_ut_t"]

  def dev_scifi_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_tracks_t"]

  def dev_atomics_scifi_t(self):
    return self.__ordered_parameters["dev_atomics_scifi_t"]

  def dev_scifi_lf_parametrization_x_filter_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_x_filter_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_quality_filter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_offsets_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_scifi_lf_length_filtered_tracks_t",
    "dev_scifi_lf_length_filtered_atomics_t",
    "dev_scifi_lf_parametrization_length_filter_t",
    "dev_ut_states_t",)
  outputs = (
    "dev_lf_quality_of_tracks_t",
    "dev_atomics_scifi_t",
    "dev_scifi_tracks_t",
    "dev_scifi_lf_y_parametrization_length_filter_t",
    "dev_scifi_lf_parametrization_consolidate_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "lf_quality_filter"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_scifi_hits_t,
    dev_scifi_hit_offsets_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_scifi_lf_length_filtered_tracks_t,
    dev_scifi_lf_length_filtered_atomics_t,
    dev_scifi_lf_parametrization_length_filter_t,
    dev_ut_states_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="lf_quality_filter_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFQualityFilter.cuh"
    self.__name = name
    self.__original_name = "lf_quality_filter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_length_filtered_tracks_t", check_input_parameter(dev_scifi_lf_length_filtered_tracks_t, DeviceInput, "int")),
      ("dev_scifi_lf_length_filtered_atomics_t", check_input_parameter(dev_scifi_lf_length_filtered_atomics_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_parametrization_length_filter_t", check_input_parameter(dev_scifi_lf_parametrization_length_filter_t, DeviceInput, "float")),
      ("dev_ut_states_t", check_input_parameter(dev_ut_states_t, DeviceInput, "int")),
      ("dev_lf_quality_of_tracks_t", DeviceOutput("dev_lf_quality_of_tracks_t", "float", self.__name)),
      ("dev_atomics_scifi_t", DeviceOutput("dev_atomics_scifi_t", "unsigned int", self.__name)),
      ("dev_scifi_tracks_t", DeviceOutput("dev_scifi_tracks_t", "int", self.__name)),
      ("dev_scifi_lf_y_parametrization_length_filter_t", DeviceOutput("dev_scifi_lf_y_parametrization_length_filter_t", "float", self.__name)),
      ("dev_scifi_lf_parametrization_consolidate_t", DeviceOutput("dev_scifi_lf_parametrization_consolidate_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_scifi_lf_length_filtered_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_lf_length_filtered_tracks_t"]

  def dev_scifi_lf_length_filtered_atomics_t(self):
    return self.__ordered_parameters["dev_scifi_lf_length_filtered_atomics_t"]

  def dev_scifi_lf_parametrization_length_filter_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_length_filter_t"]

  def dev_ut_states_t(self):
    return self.__ordered_parameters["dev_ut_states_t"]

  def dev_lf_quality_of_tracks_t(self):
    return self.__ordered_parameters["dev_lf_quality_of_tracks_t"]

  def dev_atomics_scifi_t(self):
    return self.__ordered_parameters["dev_atomics_scifi_t"]

  def dev_scifi_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_tracks_t"]

  def dev_scifi_lf_y_parametrization_length_filter_t(self):
    return self.__ordered_parameters["dev_scifi_lf_y_parametrization_length_filter_t"]

  def dev_scifi_lf_parametrization_consolidate_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_consolidate_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_quality_filter_length_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_scifi_lf_tracks_t",
    "dev_scifi_lf_atomics_t",
    "dev_scifi_lf_parametrization_t",)
  outputs = (
    "dev_scifi_lf_length_filtered_tracks_t",
    "dev_scifi_lf_length_filtered_atomics_t",
    "dev_scifi_lf_parametrization_length_filter_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "lf_quality_filter_length"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_scifi_lf_tracks_t,
    dev_scifi_lf_atomics_t,
    dev_scifi_lf_parametrization_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="lf_quality_filter_length_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFQualityFilterLength.cuh"
    self.__name = name
    self.__original_name = "lf_quality_filter_length_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_tracks_t", check_input_parameter(dev_scifi_lf_tracks_t, DeviceInput, "int")),
      ("dev_scifi_lf_atomics_t", check_input_parameter(dev_scifi_lf_atomics_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_parametrization_t", check_input_parameter(dev_scifi_lf_parametrization_t, DeviceInput, "float")),
      ("dev_scifi_lf_length_filtered_tracks_t", DeviceOutput("dev_scifi_lf_length_filtered_tracks_t", "int", self.__name)),
      ("dev_scifi_lf_length_filtered_atomics_t", DeviceOutput("dev_scifi_lf_length_filtered_atomics_t", "unsigned int", self.__name)),
      ("dev_scifi_lf_parametrization_length_filter_t", DeviceOutput("dev_scifi_lf_parametrization_length_filter_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_scifi_lf_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_lf_tracks_t"]

  def dev_scifi_lf_atomics_t(self):
    return self.__ordered_parameters["dev_scifi_lf_atomics_t"]

  def dev_scifi_lf_parametrization_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_t"]

  def dev_scifi_lf_length_filtered_tracks_t(self):
    return self.__ordered_parameters["dev_scifi_lf_length_filtered_tracks_t"]

  def dev_scifi_lf_length_filtered_atomics_t(self):
    return self.__ordered_parameters["dev_scifi_lf_length_filtered_atomics_t"]

  def dev_scifi_lf_parametrization_length_filter_t(self):
    return self.__ordered_parameters["dev_scifi_lf_parametrization_length_filter_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_search_initial_windows_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_offsets_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_x_t",
    "dev_ut_tx_t",
    "dev_ut_z_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",)
  outputs = (
    "dev_scifi_lf_initial_windows_t",
    "dev_ut_states_t",
    "dev_scifi_lf_process_track_t",)
  props = (
    "verbosity",
    "hit_window_size",
    "block_dim",)
  aggregates = ()
  namespace = "lf_search_initial_windows"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_scifi_hits_t,
    dev_scifi_hit_offsets_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_x_t,
    dev_ut_tx_t,
    dev_ut_z_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    hit_window_size=Property("unsigned int", "", "maximum hit window size"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="lf_search_initial_windows_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFSearchInitialWindows.cuh"
    self.__name = name
    self.__original_name = "lf_search_initial_windows_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_x_t", check_input_parameter(dev_ut_x_t, DeviceInput, "float")),
      ("dev_ut_tx_t", check_input_parameter(dev_ut_tx_t, DeviceInput, "float")),
      ("dev_ut_z_t", check_input_parameter(dev_ut_z_t, DeviceInput, "float")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_scifi_lf_initial_windows_t", DeviceOutput("dev_scifi_lf_initial_windows_t", "int", self.__name)),
      ("dev_ut_states_t", DeviceOutput("dev_ut_states_t", "int", self.__name)),
      ("dev_scifi_lf_process_track_t", DeviceOutput("dev_scifi_lf_process_track_t", "bool", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("hit_window_size", Property("unsigned int", "", "maximum hit window size", hit_window_size)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_x_t(self):
    return self.__ordered_parameters["dev_ut_x_t"]

  def dev_ut_tx_t(self):
    return self.__ordered_parameters["dev_ut_tx_t"]

  def dev_ut_z_t(self):
    return self.__ordered_parameters["dev_ut_z_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_scifi_lf_initial_windows_t(self):
    return self.__ordered_parameters["dev_scifi_lf_initial_windows_t"]

  def dev_ut_states_t(self):
    return self.__ordered_parameters["dev_ut_states_t"]

  def dev_scifi_lf_process_track_t(self):
    return self.__ordered_parameters["dev_scifi_lf_process_track_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def hit_window_size(self):
    return self.__ordered_properties["hit_window_size"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class lf_triplet_seeding_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_scifi_hits_t",
    "dev_scifi_hit_offsets_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_velo_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "dev_scifi_lf_initial_windows_t",
    "dev_ut_states_t",
    "dev_scifi_lf_process_track_t",)
  outputs = (
    "dev_scifi_lf_found_triplets_t",
    "dev_scifi_lf_number_of_found_triplets_t",)
  props = (
    "verbosity",
    "hit_window_size",)
  aggregates = ()
  namespace = "lf_triplet_seeding"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_scifi_hits_t,
    dev_scifi_hit_offsets_t,
    dev_offsets_all_velo_tracks_t,
    dev_velo_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    dev_scifi_lf_initial_windows_t,
    dev_ut_states_t,
    dev_scifi_lf_process_track_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    hit_window_size=Property("unsigned int", "", "maximum hit window size"),
    name="lf_triplet_seeding_t"):
    self.__filename = "device/SciFi/looking_forward/include/LFTripletSeeding.cuh"
    self.__name = name
    self.__original_name = "lf_triplet_seeding_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", check_input_parameter(dev_scifi_hits_t, DeviceInput, "char")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_scifi_lf_initial_windows_t", check_input_parameter(dev_scifi_lf_initial_windows_t, DeviceInput, "int")),
      ("dev_ut_states_t", check_input_parameter(dev_ut_states_t, DeviceInput, "int")),
      ("dev_scifi_lf_process_track_t", check_input_parameter(dev_scifi_lf_process_track_t, DeviceInput, "bool")),
      ("dev_scifi_lf_found_triplets_t", DeviceOutput("dev_scifi_lf_found_triplets_t", "int", self.__name)),
      ("dev_scifi_lf_number_of_found_triplets_t", DeviceOutput("dev_scifi_lf_number_of_found_triplets_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("hit_window_size", Property("unsigned int", "", "maximum hit window size", hit_window_size))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_scifi_lf_initial_windows_t(self):
    return self.__ordered_parameters["dev_scifi_lf_initial_windows_t"]

  def dev_ut_states_t(self):
    return self.__ordered_parameters["dev_ut_states_t"]

  def dev_scifi_lf_process_track_t(self):
    return self.__ordered_parameters["dev_scifi_lf_process_track_t"]

  def dev_scifi_lf_found_triplets_t(self):
    return self.__ordered_parameters["dev_scifi_lf_found_triplets_t"]

  def dev_scifi_lf_number_of_found_triplets_t(self):
    return self.__ordered_parameters["dev_scifi_lf_number_of_found_triplets_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def hit_window_size(self):
    return self.__ordered_properties["hit_window_size"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_calculate_cluster_count_v4_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",)
  outputs = (
    "dev_scifi_hit_count_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "scifi_calculate_cluster_count_v4"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="scifi_calculate_cluster_count_v4_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiCalculateClusterCountV4.cuh"
    self.__name = name
    self.__original_name = "scifi_calculate_cluster_count_v4_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_count_t", DeviceOutput("dev_scifi_hit_count_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_scifi_hit_count_t(self):
    return self.__ordered_parameters["dev_scifi_hit_count_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_calculate_cluster_count_v6_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",)
  outputs = (
    "dev_scifi_hit_count_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "scifi_calculate_cluster_count_v6"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="scifi_calculate_cluster_count_v6_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiCalculateClusterCountV6.cuh"
    self.__name = name
    self.__original_name = "scifi_calculate_cluster_count_v6_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_count_t", DeviceOutput("dev_scifi_hit_count_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_scifi_hit_count_t(self):
    return self.__ordered_parameters["dev_scifi_hit_count_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_pre_decode_v4_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_scifi_hits_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",
    "dev_event_list_t",
    "dev_scifi_hit_offsets_t",)
  outputs = (
    "dev_cluster_references_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "scifi_pre_decode_v4"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_scifi_hits_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    dev_event_list_t,
    dev_scifi_hit_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="scifi_pre_decode_v4_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiPreDecodeV4.cuh"
    self.__name = name
    self.__original_name = "scifi_pre_decode_v4_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_scifi_hits_t", check_input_parameter(host_accumulated_number_of_scifi_hits_t, HostInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_cluster_references_t", DeviceOutput("dev_cluster_references_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_scifi_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_scifi_hits_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_cluster_references_t(self):
    return self.__ordered_parameters["dev_cluster_references_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_pre_decode_v6_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_scifi_hits_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",
    "dev_event_list_t",
    "dev_scifi_hit_offsets_t",)
  outputs = (
    "dev_cluster_references_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "scifi_pre_decode_v6"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_scifi_hits_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    dev_event_list_t,
    dev_scifi_hit_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="scifi_pre_decode_v6_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiPreDecodeV6.cuh"
    self.__name = name
    self.__original_name = "scifi_pre_decode_v6_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_scifi_hits_t", check_input_parameter(host_accumulated_number_of_scifi_hits_t, HostInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_cluster_references_t", DeviceOutput("dev_cluster_references_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_scifi_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_scifi_hits_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_cluster_references_t(self):
    return self.__ordered_parameters["dev_cluster_references_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_raw_bank_decoder_v4_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_scifi_hits_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",
    "dev_scifi_hit_offsets_t",
    "dev_cluster_references_t",
    "dev_event_list_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_scifi_hits_t",)
  props = (
    "verbosity",
    "raw_bank_decoder_block_dim",
    "direct_decoder_block_dim",)
  aggregates = ()
  namespace = "scifi_raw_bank_decoder_v4"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_scifi_hits_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    dev_scifi_hit_offsets_t,
    dev_cluster_references_t,
    dev_event_list_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    raw_bank_decoder_block_dim=Property("DeviceDimensions", "", "block dimensions of raw bank decoder kernel"),
    direct_decoder_block_dim=Property("DeviceDimensions", "", "block dimensions of direct decoder"),
    name="scifi_raw_bank_decoder_v4_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiRawBankDecoderV4.cuh"
    self.__name = name
    self.__original_name = "scifi_raw_bank_decoder_v4_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_scifi_hits_t", check_input_parameter(host_accumulated_number_of_scifi_hits_t, HostInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_cluster_references_t", check_input_parameter(dev_cluster_references_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", DeviceOutput("dev_scifi_hits_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("raw_bank_decoder_block_dim", Property("DeviceDimensions", "", "block dimensions of raw bank decoder kernel", raw_bank_decoder_block_dim)),
      ("direct_decoder_block_dim", Property("DeviceDimensions", "", "block dimensions of direct decoder", direct_decoder_block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_scifi_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_scifi_hits_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_cluster_references_t(self):
    return self.__ordered_parameters["dev_cluster_references_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def raw_bank_decoder_block_dim(self):
    return self.__ordered_properties["raw_bank_decoder_block_dim"]

  def direct_decoder_block_dim(self):
    return self.__ordered_properties["direct_decoder_block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class scifi_raw_bank_decoder_v6_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_scifi_hits_t",
    "dev_scifi_raw_input_t",
    "dev_scifi_raw_input_offsets_t",
    "dev_scifi_hit_offsets_t",
    "dev_cluster_references_t",
    "dev_event_list_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_scifi_hits_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "scifi_raw_bank_decoder_v6"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_scifi_hits_t,
    dev_scifi_raw_input_t,
    dev_scifi_raw_input_offsets_t,
    dev_scifi_hit_offsets_t,
    dev_cluster_references_t,
    dev_event_list_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="scifi_raw_bank_decoder_v6_t"):
    self.__filename = "device/SciFi/preprocessing/include/SciFiRawBankDecoderV6.cuh"
    self.__name = name
    self.__original_name = "scifi_raw_bank_decoder_v6_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_scifi_hits_t", check_input_parameter(host_accumulated_number_of_scifi_hits_t, HostInput, "unsigned int")),
      ("dev_scifi_raw_input_t", check_input_parameter(dev_scifi_raw_input_t, DeviceInput, "char")),
      ("dev_scifi_raw_input_offsets_t", check_input_parameter(dev_scifi_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hit_offsets_t", check_input_parameter(dev_scifi_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_cluster_references_t", check_input_parameter(dev_cluster_references_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_scifi_hits_t", DeviceOutput("dev_scifi_hits_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_scifi_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_scifi_hits_t"]

  def dev_scifi_raw_input_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_t"]

  def dev_scifi_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_raw_input_offsets_t"]

  def dev_scifi_hit_offsets_t(self):
    return self.__ordered_parameters["dev_scifi_hit_offsets_t"]

  def dev_cluster_references_t(self):
    return self.__ordered_parameters["dev_cluster_references_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_scifi_hits_t(self):
    return self.__ordered_parameters["dev_scifi_hits_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_calculate_number_of_hits_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_ut_raw_input_t",
    "dev_ut_raw_input_offsets_t",)
  outputs = (
    "dev_ut_hit_sizes_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_calculate_number_of_hits"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_ut_raw_input_t,
    dev_ut_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_calculate_number_of_hits_t"):
    self.__filename = "device/UT/UTDecoding/include/UTCalculateNumberOfHits.cuh"
    self.__name = name
    self.__original_name = "ut_calculate_number_of_hits_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_raw_input_t", check_input_parameter(dev_ut_raw_input_t, DeviceInput, "char")),
      ("dev_ut_raw_input_offsets_t", check_input_parameter(dev_ut_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_ut_hit_sizes_t", DeviceOutput("dev_ut_hit_sizes_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_raw_input_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_t"]

  def dev_ut_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_offsets_t"]

  def dev_ut_hit_sizes_t(self):
    return self.__ordered_parameters["dev_ut_hit_sizes_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_decode_raw_banks_in_order_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_ut_hits_t",
    "dev_number_of_events_t",
    "dev_ut_raw_input_t",
    "dev_ut_raw_input_offsets_t",
    "dev_event_list_t",
    "dev_ut_hit_offsets_t",
    "dev_ut_pre_decoded_hits_t",
    "dev_ut_hit_permutations_t",)
  outputs = (
    "dev_ut_hits_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_decode_raw_banks_in_order"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_ut_hits_t,
    dev_number_of_events_t,
    dev_ut_raw_input_t,
    dev_ut_raw_input_offsets_t,
    dev_event_list_t,
    dev_ut_hit_offsets_t,
    dev_ut_pre_decoded_hits_t,
    dev_ut_hit_permutations_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_decode_raw_banks_in_order_t"):
    self.__filename = "device/UT/UTDecoding/include/UTDecodeRawBanksInOrder.cuh"
    self.__name = name
    self.__original_name = "ut_decode_raw_banks_in_order_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_ut_hits_t", check_input_parameter(host_accumulated_number_of_ut_hits_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ut_raw_input_t", check_input_parameter(dev_ut_raw_input_t, DeviceInput, "char")),
      ("dev_ut_raw_input_offsets_t", check_input_parameter(dev_ut_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_ut_pre_decoded_hits_t", check_input_parameter(dev_ut_pre_decoded_hits_t, DeviceInput, "char")),
      ("dev_ut_hits_t", DeviceOutput("dev_ut_hits_t", "char", self.__name)),
      ("dev_ut_hit_permutations_t", check_input_parameter(dev_ut_hit_permutations_t, DeviceInput, "unsigned int"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_ut_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_ut_hits_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ut_raw_input_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_t"]

  def dev_ut_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_ut_pre_decoded_hits_t(self):
    return self.__ordered_parameters["dev_ut_pre_decoded_hits_t"]

  def dev_ut_hits_t(self):
    return self.__ordered_parameters["dev_ut_hits_t"]

  def dev_ut_hit_permutations_t(self):
    return self.__ordered_parameters["dev_ut_hit_permutations_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_find_permutation_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_ut_hits_t",
    "dev_number_of_events_t",
    "dev_event_list_t",
    "dev_ut_pre_decoded_hits_t",
    "dev_ut_hit_offsets_t",)
  outputs = (
    "dev_ut_hit_permutations_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_find_permutation"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_ut_hits_t,
    dev_number_of_events_t,
    dev_event_list_t,
    dev_ut_pre_decoded_hits_t,
    dev_ut_hit_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_find_permutation_t"):
    self.__filename = "device/UT/UTDecoding/include/UTFindPermutation.cuh"
    self.__name = name
    self.__original_name = "ut_find_permutation_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_ut_hits_t", check_input_parameter(host_accumulated_number_of_ut_hits_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_pre_decoded_hits_t", check_input_parameter(dev_ut_pre_decoded_hits_t, DeviceInput, "char")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_ut_hit_permutations_t", DeviceOutput("dev_ut_hit_permutations_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_ut_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_ut_hits_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_pre_decoded_hits_t(self):
    return self.__ordered_parameters["dev_ut_pre_decoded_hits_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_ut_hit_permutations_t(self):
    return self.__ordered_parameters["dev_ut_hit_permutations_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_pre_decode_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_accumulated_number_of_ut_hits_t",
    "dev_number_of_events_t",
    "dev_ut_raw_input_t",
    "dev_ut_raw_input_offsets_t",
    "dev_event_list_t",
    "dev_ut_hit_offsets_t",)
  outputs = (
    "dev_ut_pre_decoded_hits_t",
    "dev_ut_hit_count_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_pre_decode"

  def __init__(self,
    host_number_of_events_t,
    host_accumulated_number_of_ut_hits_t,
    dev_number_of_events_t,
    dev_ut_raw_input_t,
    dev_ut_raw_input_offsets_t,
    dev_event_list_t,
    dev_ut_hit_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_pre_decode_t"):
    self.__filename = "device/UT/UTDecoding/include/UTPreDecode.cuh"
    self.__name = name
    self.__original_name = "ut_pre_decode_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_ut_hits_t", check_input_parameter(host_accumulated_number_of_ut_hits_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ut_raw_input_t", check_input_parameter(dev_ut_raw_input_t, DeviceInput, "char")),
      ("dev_ut_raw_input_offsets_t", check_input_parameter(dev_ut_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_ut_pre_decoded_hits_t", DeviceOutput("dev_ut_pre_decoded_hits_t", "char", self.__name)),
      ("dev_ut_hit_count_t", DeviceOutput("dev_ut_hit_count_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_ut_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_ut_hits_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ut_raw_input_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_t"]

  def dev_ut_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_ut_raw_input_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_ut_pre_decoded_hits_t(self):
    return self.__ordered_parameters["dev_ut_pre_decoded_hits_t"]

  def dev_ut_hit_count_t(self):
    return self.__ordered_parameters["dev_ut_hit_count_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class compass_ut_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_number_of_events_t",
    "dev_ut_hits_t",
    "dev_ut_hit_offsets_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_ut_windows_layers_t",
    "dev_ut_number_of_selected_velo_tracks_with_windows_t",
    "dev_ut_selected_velo_tracks_with_windows_t",
    "dev_event_list_t",)
  outputs = (
    "dev_ut_tracks_t",
    "dev_atomics_ut_t",)
  props = (
    "verbosity",
    "sigma_velo_slope",
    "min_momentum_final",
    "min_pt_final",
    "hit_tol_2",
    "delta_tx_2",
    "max_considered_before_found",)
  aggregates = ()
  namespace = "compass_ut"

  def __init__(self,
    host_number_of_events_t,
    dev_number_of_events_t,
    dev_ut_hits_t,
    dev_ut_hit_offsets_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_ut_windows_layers_t,
    dev_ut_number_of_selected_velo_tracks_with_windows_t,
    dev_ut_selected_velo_tracks_with_windows_t,
    dev_event_list_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    sigma_velo_slope=Property("float", "", "sigma velo slope [radians]"),
    min_momentum_final=Property("float", "", "final min momentum cut [MeV/c]"),
    min_pt_final=Property("float", "", "final min pT cut [MeV/c]"),
    hit_tol_2=Property("float", "", "hit_tol_2 [mm]"),
    delta_tx_2=Property("float", "", "delta_tx_2"),
    max_considered_before_found=Property("unsigned int", "", "max_considered_before_found"),
    name="compass_ut_t"):
    self.__filename = "device/UT/compassUT/include/CompassUT.cuh"
    self.__name = name
    self.__original_name = "compass_ut_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ut_hits_t", check_input_parameter(dev_ut_hits_t, DeviceInput, "char")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_ut_windows_layers_t", check_input_parameter(dev_ut_windows_layers_t, DeviceInput, "short")),
      ("dev_ut_number_of_selected_velo_tracks_with_windows_t", check_input_parameter(dev_ut_number_of_selected_velo_tracks_with_windows_t, DeviceInput, "unsigned int")),
      ("dev_ut_selected_velo_tracks_with_windows_t", check_input_parameter(dev_ut_selected_velo_tracks_with_windows_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_tracks_t", DeviceOutput("dev_ut_tracks_t", "int", self.__name)),
      ("dev_atomics_ut_t", DeviceOutput("dev_atomics_ut_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("sigma_velo_slope", Property("float", "", "sigma velo slope [radians]", sigma_velo_slope)),
      ("min_momentum_final", Property("float", "", "final min momentum cut [MeV/c]", min_momentum_final)),
      ("min_pt_final", Property("float", "", "final min pT cut [MeV/c]", min_pt_final)),
      ("hit_tol_2", Property("float", "", "hit_tol_2 [mm]", hit_tol_2)),
      ("delta_tx_2", Property("float", "", "delta_tx_2", delta_tx_2)),
      ("max_considered_before_found", Property("unsigned int", "", "max_considered_before_found", max_considered_before_found))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ut_hits_t(self):
    return self.__ordered_parameters["dev_ut_hits_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_ut_windows_layers_t(self):
    return self.__ordered_parameters["dev_ut_windows_layers_t"]

  def dev_ut_number_of_selected_velo_tracks_with_windows_t(self):
    return self.__ordered_parameters["dev_ut_number_of_selected_velo_tracks_with_windows_t"]

  def dev_ut_selected_velo_tracks_with_windows_t(self):
    return self.__ordered_parameters["dev_ut_selected_velo_tracks_with_windows_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_tracks_t(self):
    return self.__ordered_parameters["dev_ut_tracks_t"]

  def dev_atomics_ut_t(self):
    return self.__ordered_parameters["dev_atomics_ut_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def sigma_velo_slope(self):
    return self.__ordered_properties["sigma_velo_slope"]

  def min_momentum_final(self):
    return self.__ordered_properties["min_momentum_final"]

  def min_pt_final(self):
    return self.__ordered_properties["min_pt_final"]

  def hit_tol_2(self):
    return self.__ordered_properties["hit_tol_2"]

  def delta_tx_2(self):
    return self.__ordered_properties["delta_tx_2"]

  def max_considered_before_found(self):
    return self.__ordered_properties["max_considered_before_found"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_search_windows_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_number_of_events_t",
    "dev_ut_hits_t",
    "dev_ut_hit_offsets_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_ut_number_of_selected_velo_tracks_t",
    "dev_ut_selected_velo_tracks_t",
    "dev_event_list_t",)
  outputs = (
    "dev_ut_windows_layers_t",)
  props = (
    "verbosity",
    "min_momentum",
    "min_pt",
    "y_tol",
    "y_tol_slope",
    "block_dim_y_t",)
  aggregates = ()
  namespace = "ut_search_windows"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_number_of_events_t,
    dev_ut_hits_t,
    dev_ut_hit_offsets_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_ut_number_of_selected_velo_tracks_t,
    dev_ut_selected_velo_tracks_t,
    dev_event_list_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    min_momentum=Property("float", "", "min momentum cut [MeV/c]"),
    min_pt=Property("float", "", "min pT cut [MeV/c]"),
    y_tol=Property("float", "", "y tol [mm]"),
    y_tol_slope=Property("float", "", "y tol slope [mm]"),
    block_dim_y_t=Property("unsigned int", "", "block dimension Y"),
    name="ut_search_windows_t"):
    self.__filename = "device/UT/compassUT/include/SearchWindows.cuh"
    self.__name = name
    self.__original_name = "ut_search_windows_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ut_hits_t", check_input_parameter(dev_ut_hits_t, DeviceInput, "char")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_ut_number_of_selected_velo_tracks_t", check_input_parameter(dev_ut_number_of_selected_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_ut_selected_velo_tracks_t", check_input_parameter(dev_ut_selected_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_windows_layers_t", DeviceOutput("dev_ut_windows_layers_t", "short", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("min_momentum", Property("float", "", "min momentum cut [MeV/c]", min_momentum)),
      ("min_pt", Property("float", "", "min pT cut [MeV/c]", min_pt)),
      ("y_tol", Property("float", "", "y tol [mm]", y_tol)),
      ("y_tol_slope", Property("float", "", "y tol slope [mm]", y_tol_slope)),
      ("block_dim_y_t", Property("unsigned int", "", "block dimension Y", block_dim_y_t))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ut_hits_t(self):
    return self.__ordered_parameters["dev_ut_hits_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_ut_number_of_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_number_of_selected_velo_tracks_t"]

  def dev_ut_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_selected_velo_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_windows_layers_t(self):
    return self.__ordered_parameters["dev_ut_windows_layers_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def min_momentum(self):
    return self.__ordered_properties["min_momentum"]

  def min_pt(self):
    return self.__ordered_properties["min_pt"]

  def y_tol(self):
    return self.__ordered_properties["y_tol"]

  def y_tol_slope(self):
    return self.__ordered_properties["y_tol_slope"]

  def block_dim_y_t(self):
    return self.__ordered_properties["block_dim_y_t"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_select_velo_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_states_t",
    "dev_accepted_velo_tracks_t",
    "dev_event_list_t",
    "dev_velo_track_hits_t",)
  outputs = (
    "dev_ut_number_of_selected_velo_tracks_t",
    "dev_ut_selected_velo_tracks_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_select_velo_tracks"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_states_t,
    dev_accepted_velo_tracks_t,
    dev_event_list_t,
    dev_velo_track_hits_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_select_velo_tracks_t"):
    self.__filename = "device/UT/compassUT/include/UTSelectVeloTracks.cuh"
    self.__name = name
    self.__original_name = "ut_select_velo_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_states_t", check_input_parameter(dev_velo_states_t, DeviceInput, "char")),
      ("dev_accepted_velo_tracks_t", check_input_parameter(dev_accepted_velo_tracks_t, DeviceInput, "bool")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_ut_number_of_selected_velo_tracks_t", DeviceOutput("dev_ut_number_of_selected_velo_tracks_t", "unsigned int", self.__name)),
      ("dev_ut_selected_velo_tracks_t", DeviceOutput("dev_ut_selected_velo_tracks_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_states_t(self):
    return self.__ordered_parameters["dev_velo_states_t"]

  def dev_accepted_velo_tracks_t(self):
    return self.__ordered_parameters["dev_accepted_velo_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_ut_number_of_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_number_of_selected_velo_tracks_t"]

  def dev_ut_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_selected_velo_tracks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_select_velo_tracks_with_windows_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_accepted_velo_tracks_t",
    "dev_ut_number_of_selected_velo_tracks_t",
    "dev_ut_selected_velo_tracks_t",
    "dev_ut_windows_layers_t",
    "dev_event_list_t",)
  outputs = (
    "dev_ut_number_of_selected_velo_tracks_with_windows_t",
    "dev_ut_selected_velo_tracks_with_windows_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_select_velo_tracks_with_windows"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_velo_tracks_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_accepted_velo_tracks_t,
    dev_ut_number_of_selected_velo_tracks_t,
    dev_ut_selected_velo_tracks_t,
    dev_ut_windows_layers_t,
    dev_event_list_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_select_velo_tracks_with_windows_t"):
    self.__filename = "device/UT/compassUT/include/UTSelectVeloTracksWithWindows.cuh"
    self.__name = name
    self.__original_name = "ut_select_velo_tracks_with_windows_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_accepted_velo_tracks_t", check_input_parameter(dev_accepted_velo_tracks_t, DeviceInput, "bool")),
      ("dev_ut_number_of_selected_velo_tracks_t", check_input_parameter(dev_ut_number_of_selected_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_ut_selected_velo_tracks_t", check_input_parameter(dev_ut_selected_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_ut_windows_layers_t", check_input_parameter(dev_ut_windows_layers_t, DeviceInput, "short")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_number_of_selected_velo_tracks_with_windows_t", DeviceOutput("dev_ut_number_of_selected_velo_tracks_with_windows_t", "unsigned int", self.__name)),
      ("dev_ut_selected_velo_tracks_with_windows_t", DeviceOutput("dev_ut_selected_velo_tracks_with_windows_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_accepted_velo_tracks_t(self):
    return self.__ordered_parameters["dev_accepted_velo_tracks_t"]

  def dev_ut_number_of_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_number_of_selected_velo_tracks_t"]

  def dev_ut_selected_velo_tracks_t(self):
    return self.__ordered_parameters["dev_ut_selected_velo_tracks_t"]

  def dev_ut_windows_layers_t(self):
    return self.__ordered_parameters["dev_ut_windows_layers_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_number_of_selected_velo_tracks_with_windows_t(self):
    return self.__ordered_parameters["dev_ut_number_of_selected_velo_tracks_with_windows_t"]

  def dev_ut_selected_velo_tracks_with_windows_t(self):
    return self.__ordered_parameters["dev_ut_selected_velo_tracks_with_windows_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_consolidate_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_accumulated_number_of_ut_hits_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "host_number_of_events_t",
    "host_accumulated_number_of_hits_in_ut_tracks_t",
    "dev_number_of_events_t",
    "dev_ut_hits_t",
    "dev_ut_hit_offsets_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_tracks_t",
    "dev_event_list_t",)
  outputs = (
    "dev_ut_track_hits_t",
    "dev_ut_qop_t",
    "dev_ut_x_t",
    "dev_ut_tx_t",
    "dev_ut_z_t",
    "dev_ut_track_velo_indices_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_consolidate_tracks"

  def __init__(self,
    host_accumulated_number_of_ut_hits_t,
    host_number_of_reconstructed_ut_tracks_t,
    host_number_of_events_t,
    host_accumulated_number_of_hits_in_ut_tracks_t,
    dev_number_of_events_t,
    dev_ut_hits_t,
    dev_ut_hit_offsets_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_tracks_t,
    dev_event_list_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_consolidate_tracks_t"):
    self.__filename = "device/UT/consolidate/include/ConsolidateUT.cuh"
    self.__name = name
    self.__original_name = "ut_consolidate_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_accumulated_number_of_ut_hits_t", check_input_parameter(host_accumulated_number_of_ut_hits_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_accumulated_number_of_hits_in_ut_tracks_t", check_input_parameter(host_accumulated_number_of_hits_in_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ut_hits_t", check_input_parameter(dev_ut_hits_t, DeviceInput, "char")),
      ("dev_ut_hit_offsets_t", check_input_parameter(dev_ut_hit_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_tracks_t", check_input_parameter(dev_ut_tracks_t, DeviceInput, "int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", DeviceOutput("dev_ut_track_hits_t", "char", self.__name)),
      ("dev_ut_qop_t", DeviceOutput("dev_ut_qop_t", "float", self.__name)),
      ("dev_ut_x_t", DeviceOutput("dev_ut_x_t", "float", self.__name)),
      ("dev_ut_tx_t", DeviceOutput("dev_ut_tx_t", "float", self.__name)),
      ("dev_ut_z_t", DeviceOutput("dev_ut_z_t", "float", self.__name)),
      ("dev_ut_track_velo_indices_t", DeviceOutput("dev_ut_track_velo_indices_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_accumulated_number_of_ut_hits_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_ut_hits_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_accumulated_number_of_hits_in_ut_tracks_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_hits_in_ut_tracks_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ut_hits_t(self):
    return self.__ordered_parameters["dev_ut_hits_t"]

  def dev_ut_hit_offsets_t(self):
    return self.__ordered_parameters["dev_ut_hit_offsets_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_tracks_t(self):
    return self.__ordered_parameters["dev_ut_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_x_t(self):
    return self.__ordered_parameters["dev_ut_x_t"]

  def dev_ut_tx_t(self):
    return self.__ordered_parameters["dev_ut_tx_t"]

  def dev_ut_z_t(self):
    return self.__ordered_parameters["dev_ut_z_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class ut_copy_track_hit_number_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_ut_tracks_t",
    "dev_ut_tracks_t",
    "dev_offsets_ut_tracks_t",)
  outputs = (
    "dev_ut_track_hit_number_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "ut_copy_track_hit_number"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_ut_tracks_t,
    dev_ut_tracks_t,
    dev_offsets_ut_tracks_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="ut_copy_track_hit_number_t"):
    self.__filename = "device/UT/consolidate/include/UTCopyTrackHitNumber.cuh"
    self.__name = name
    self.__original_name = "ut_copy_track_hit_number_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_ut_tracks_t", check_input_parameter(host_number_of_reconstructed_ut_tracks_t, HostInput, "unsigned int")),
      ("dev_ut_tracks_t", check_input_parameter(dev_ut_tracks_t, DeviceInput, "int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hit_number_t", DeviceOutput("dev_ut_track_hit_number_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_ut_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_ut_tracks_t"]

  def dev_ut_tracks_t(self):
    return self.__ordered_parameters["dev_ut_tracks_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_ut_track_hit_number_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_pv_ip_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_reconstructed_velo_tracks_t",
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",)
  outputs = (
    "dev_velo_pv_ip_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_pv_ip"

  def __init__(self,
    host_number_of_reconstructed_velo_tracks_t,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_velo_kalman_beamline_states_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_pv_ip_t"):
    self.__filename = "device/associate/include/VeloPVIP.cuh"
    self.__name = name
    self.__original_name = "velo_pv_ip_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("dev_velo_pv_ip_t", DeviceOutput("dev_velo_pv_ip_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def dev_velo_pv_ip_t(self):
    return self.__ordered_parameters["dev_velo_pv_ip_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class saxpy_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",)
  outputs = (
    "dev_saxpy_output_t",)
  props = (
    "verbosity",
    "saxpy_scale_factor",
    "block_dim",)
  aggregates = ()
  namespace = "saxpy"

  def __init__(self,
    host_number_of_events_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    saxpy_scale_factor=Property("float", "", "scale factor a used in a*x + y"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="saxpy_t"):
    self.__filename = "device/example/include/SAXPY_example.cuh"
    self.__name = name
    self.__original_name = "saxpy_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_saxpy_output_t", DeviceOutput("dev_saxpy_output_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("saxpy_scale_factor", Property("float", "", "scale factor a used in a*x + y", saxpy_scale_factor)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_saxpy_output_t(self):
    return self.__ordered_parameters["dev_saxpy_output_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def saxpy_scale_factor(self):
    return self.__ordered_properties["saxpy_scale_factor"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class package_kalman_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_atomics_velo_t",
    "dev_velo_track_hit_number_t",
    "dev_atomics_ut_t",
    "dev_ut_track_hit_number_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_atomics_scifi_t",
    "dev_scifi_track_hit_number_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_is_muon_t",)
  outputs = (
    "dev_kf_tracks_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "package_kalman_tracks"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_atomics_velo_t,
    dev_velo_track_hit_number_t,
    dev_atomics_ut_t,
    dev_ut_track_hit_number_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_atomics_scifi_t,
    dev_scifi_track_hit_number_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_velo_kalman_beamline_states_t,
    dev_is_muon_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="package_kalman_tracks_t"):
    self.__filename = "device/kalman/ParKalman/include/PackageKalman.cuh"
    self.__name = name
    self.__original_name = "package_kalman_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_atomics_velo_t", check_input_parameter(dev_atomics_velo_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hit_number_t", check_input_parameter(dev_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_atomics_ut_t", check_input_parameter(dev_atomics_ut_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hit_number_t", check_input_parameter(dev_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_atomics_scifi_t", check_input_parameter(dev_atomics_scifi_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hit_number_t", check_input_parameter(dev_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_is_muon_t", check_input_parameter(dev_is_muon_t, DeviceInput, "bool")),
      ("dev_kf_tracks_t", DeviceOutput("dev_kf_tracks_t", "ParKalmanFilter::FittedTrack", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_velo_track_hit_number_t"]

  def dev_atomics_ut_t(self):
    return self.__ordered_parameters["dev_atomics_ut_t"]

  def dev_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_ut_track_hit_number_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_atomics_scifi_t(self):
    return self.__ordered_parameters["dev_atomics_scifi_t"]

  def dev_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_scifi_track_hit_number_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_is_muon_t(self):
    return self.__ordered_parameters["dev_is_muon_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class package_mf_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_mf_tracks_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_match_upstream_muon_t",
    "dev_event_list_mf_t",
    "dev_mf_track_offsets_t",)
  outputs = (
    "host_selected_events_mf_t",
    "dev_mf_tracks_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "package_mf_tracks"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_mf_tracks_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_velo_kalman_beamline_states_t,
    dev_match_upstream_muon_t,
    dev_event_list_mf_t,
    dev_mf_track_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="package_mf_tracks_t"):
    self.__filename = "device/kalman/ParKalman/include/PackageMFTracks.cuh"
    self.__name = name
    self.__original_name = "package_mf_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_mf_tracks_t", check_input_parameter(host_number_of_mf_tracks_t, HostInput, "unsigned int")),
      ("host_selected_events_mf_t", HostOutput("host_selected_events_mf_t", "unsigned int", self.__name)),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_match_upstream_muon_t", check_input_parameter(dev_match_upstream_muon_t, DeviceInput, "bool")),
      ("dev_event_list_mf_t", check_input_parameter(dev_event_list_mf_t, DeviceInput, "unsigned int")),
      ("dev_mf_track_offsets_t", check_input_parameter(dev_mf_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mf_tracks_t", DeviceOutput("dev_mf_tracks_t", "ParKalmanFilter::FittedTrack", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_mf_tracks_t(self):
    return self.__ordered_parameters["host_number_of_mf_tracks_t"]

  def host_selected_events_mf_t(self):
    return self.__ordered_parameters["host_selected_events_mf_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_match_upstream_muon_t(self):
    return self.__ordered_parameters["dev_match_upstream_muon_t"]

  def dev_event_list_mf_t(self):
    return self.__ordered_parameters["dev_event_list_mf_t"]

  def dev_mf_track_offsets_t(self):
    return self.__ordered_parameters["dev_mf_track_offsets_t"]

  def dev_mf_tracks_t(self):
    return self.__ordered_parameters["dev_mf_tracks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class kalman_filter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_atomics_velo_t",
    "dev_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_atomics_ut_t",
    "dev_ut_track_hit_number_t",
    "dev_ut_track_hits_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_atomics_scifi_t",
    "dev_scifi_track_hit_number_t",
    "dev_scifi_track_hits_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",)
  outputs = (
    "dev_kf_tracks_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "kalman_filter"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_atomics_velo_t,
    dev_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_atomics_ut_t,
    dev_ut_track_hit_number_t,
    dev_ut_track_hits_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_atomics_scifi_t,
    dev_scifi_track_hit_number_t,
    dev_scifi_track_hits_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="kalman_filter_t"):
    self.__filename = "device/kalman/ParKalman/include/ParKalmanFilter.cuh"
    self.__name = name
    self.__original_name = "kalman_filter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_atomics_velo_t", check_input_parameter(dev_atomics_velo_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hit_number_t", check_input_parameter(dev_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_atomics_ut_t", check_input_parameter(dev_atomics_ut_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hit_number_t", check_input_parameter(dev_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", check_input_parameter(dev_ut_track_hits_t, DeviceInput, "char")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_atomics_scifi_t", check_input_parameter(dev_atomics_scifi_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hit_number_t", check_input_parameter(dev_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hits_t", check_input_parameter(dev_scifi_track_hits_t, DeviceInput, "char")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_kf_tracks_t", DeviceOutput("dev_kf_tracks_t", "ParKalmanFilter::FittedTrack", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_atomics_ut_t(self):
    return self.__ordered_parameters["dev_atomics_ut_t"]

  def dev_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_ut_track_hit_number_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_atomics_scifi_t(self):
    return self.__ordered_parameters["dev_atomics_scifi_t"]

  def dev_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_scifi_track_hit_number_t"]

  def dev_scifi_track_hits_t(self):
    return self.__ordered_parameters["dev_scifi_track_hits_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class kalman_velo_only_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_velo_pv_ip_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",
    "dev_is_muon_t",)
  outputs = (
    "dev_kf_tracks_t",
    "dev_kalman_pv_ipchi2_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "kalman_velo_only"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_velo_pv_ip_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    dev_is_muon_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="kalman_velo_only_t"):
    self.__filename = "device/kalman/ParKalman/include/ParKalmanVeloOnly.cuh"
    self.__name = name
    self.__original_name = "kalman_velo_only_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_velo_pv_ip_t", check_input_parameter(dev_velo_pv_ip_t, DeviceInput, "char")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("dev_is_muon_t", check_input_parameter(dev_is_muon_t, DeviceInput, "bool")),
      ("dev_kf_tracks_t", DeviceOutput("dev_kf_tracks_t", "ParKalmanFilter::FittedTrack", self.__name)),
      ("dev_kalman_pv_ipchi2_t", DeviceOutput("dev_kalman_pv_ipchi2_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_velo_pv_ip_t(self):
    return self.__ordered_parameters["dev_velo_pv_ip_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def dev_is_muon_t(self):
    return self.__ordered_parameters["dev_is_muon_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_kalman_pv_ipchi2_t(self):
    return self.__ordered_parameters["dev_kalman_pv_ipchi2_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_catboost_evaluator_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_muon_catboost_features_t",)
  outputs = (
    "dev_muon_catboost_output_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "muon_catboost_evaluator"

  def __init__(self,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_muon_catboost_features_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="muon_catboost_evaluator_t"):
    self.__filename = "device/muon/classification/include/MuonCatboostEvaluator.cuh"
    self.__name = name
    self.__original_name = "muon_catboost_evaluator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_muon_catboost_features_t", check_input_parameter(dev_muon_catboost_features_t, DeviceInput, "float")),
      ("dev_muon_catboost_output_t", DeviceOutput("dev_muon_catboost_output_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_muon_catboost_features_t(self):
    return self.__ordered_parameters["dev_muon_catboost_features_t"]

  def dev_muon_catboost_output_t(self):
    return self.__ordered_parameters["dev_muon_catboost_output_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_add_coords_crossing_maps_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_muon_total_number_of_tiles_t",
    "dev_storage_station_region_quarter_offsets_t",
    "dev_storage_tile_id_t",
    "dev_muon_raw_to_hits_t",
    "dev_event_list_t",)
  outputs = (
    "dev_atomics_index_insert_t",
    "dev_muon_compact_hit_t",
    "dev_muon_tile_used_t",
    "dev_station_ocurrences_sizes_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "muon_add_coords_crossing_maps"

  def __init__(self,
    host_number_of_events_t,
    host_muon_total_number_of_tiles_t,
    dev_storage_station_region_quarter_offsets_t,
    dev_storage_tile_id_t,
    dev_muon_raw_to_hits_t,
    dev_event_list_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="muon_add_coords_crossing_maps_t"):
    self.__filename = "device/muon/decoding/include/MuonAddCoordsCrossingMaps.cuh"
    self.__name = name
    self.__original_name = "muon_add_coords_crossing_maps_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_muon_total_number_of_tiles_t", check_input_parameter(host_muon_total_number_of_tiles_t, HostInput, "unsigned int")),
      ("dev_storage_station_region_quarter_offsets_t", check_input_parameter(dev_storage_station_region_quarter_offsets_t, DeviceInput, "unsigned int")),
      ("dev_storage_tile_id_t", check_input_parameter(dev_storage_tile_id_t, DeviceInput, "unsigned int")),
      ("dev_muon_raw_to_hits_t", check_input_parameter(dev_muon_raw_to_hits_t, DeviceInput, "int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_atomics_index_insert_t", DeviceOutput("dev_atomics_index_insert_t", "unsigned int", self.__name)),
      ("dev_muon_compact_hit_t", DeviceOutput("dev_muon_compact_hit_t", "int", self.__name)),
      ("dev_muon_tile_used_t", DeviceOutput("dev_muon_tile_used_t", "bool", self.__name)),
      ("dev_station_ocurrences_sizes_t", DeviceOutput("dev_station_ocurrences_sizes_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_muon_total_number_of_tiles_t(self):
    return self.__ordered_parameters["host_muon_total_number_of_tiles_t"]

  def dev_storage_station_region_quarter_offsets_t(self):
    return self.__ordered_parameters["dev_storage_station_region_quarter_offsets_t"]

  def dev_storage_tile_id_t(self):
    return self.__ordered_parameters["dev_storage_tile_id_t"]

  def dev_muon_raw_to_hits_t(self):
    return self.__ordered_parameters["dev_muon_raw_to_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_atomics_index_insert_t(self):
    return self.__ordered_parameters["dev_atomics_index_insert_t"]

  def dev_muon_compact_hit_t(self):
    return self.__ordered_parameters["dev_muon_compact_hit_t"]

  def dev_muon_tile_used_t(self):
    return self.__ordered_parameters["dev_muon_tile_used_t"]

  def dev_station_ocurrences_sizes_t(self):
    return self.__ordered_parameters["dev_station_ocurrences_sizes_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_calculate_srq_size_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_muon_raw_t",
    "dev_muon_raw_offsets_t",)
  outputs = (
    "dev_muon_raw_to_hits_t",
    "dev_storage_station_region_quarter_sizes_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "muon_calculate_srq_size"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_muon_raw_t,
    dev_muon_raw_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="muon_calculate_srq_size_t"):
    self.__filename = "device/muon/decoding/include/MuonCalculateSRQSize.cuh"
    self.__name = name
    self.__original_name = "muon_calculate_srq_size_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_muon_raw_t", check_input_parameter(dev_muon_raw_t, DeviceInput, "char")),
      ("dev_muon_raw_offsets_t", check_input_parameter(dev_muon_raw_offsets_t, DeviceInput, "unsigned int")),
      ("dev_muon_raw_to_hits_t", DeviceOutput("dev_muon_raw_to_hits_t", "int", self.__name)),
      ("dev_storage_station_region_quarter_sizes_t", DeviceOutput("dev_storage_station_region_quarter_sizes_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_muon_raw_t(self):
    return self.__ordered_parameters["dev_muon_raw_t"]

  def dev_muon_raw_offsets_t(self):
    return self.__ordered_parameters["dev_muon_raw_offsets_t"]

  def dev_muon_raw_to_hits_t(self):
    return self.__ordered_parameters["dev_muon_raw_to_hits_t"]

  def dev_storage_station_region_quarter_sizes_t(self):
    return self.__ordered_parameters["dev_storage_station_region_quarter_sizes_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_populate_hits_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_muon_total_number_of_hits_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_storage_tile_id_t",
    "dev_storage_tdc_value_t",
    "dev_station_ocurrences_offset_t",
    "dev_muon_compact_hit_t",
    "dev_muon_raw_to_hits_t",
    "dev_storage_station_region_quarter_offsets_t",)
  outputs = (
    "dev_permutation_station_t",
    "dev_muon_hits_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "muon_populate_hits"

  def __init__(self,
    host_number_of_events_t,
    host_muon_total_number_of_hits_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_storage_tile_id_t,
    dev_storage_tdc_value_t,
    dev_station_ocurrences_offset_t,
    dev_muon_compact_hit_t,
    dev_muon_raw_to_hits_t,
    dev_storage_station_region_quarter_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="muon_populate_hits_t"):
    self.__filename = "device/muon/decoding/include/MuonPopulateHits.cuh"
    self.__name = name
    self.__original_name = "muon_populate_hits_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_muon_total_number_of_hits_t", check_input_parameter(host_muon_total_number_of_hits_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_storage_tile_id_t", check_input_parameter(dev_storage_tile_id_t, DeviceInput, "unsigned int")),
      ("dev_storage_tdc_value_t", check_input_parameter(dev_storage_tdc_value_t, DeviceInput, "unsigned int")),
      ("dev_station_ocurrences_offset_t", check_input_parameter(dev_station_ocurrences_offset_t, DeviceInput, "unsigned int")),
      ("dev_muon_compact_hit_t", check_input_parameter(dev_muon_compact_hit_t, DeviceInput, "int")),
      ("dev_muon_raw_to_hits_t", check_input_parameter(dev_muon_raw_to_hits_t, DeviceInput, "int")),
      ("dev_storage_station_region_quarter_offsets_t", check_input_parameter(dev_storage_station_region_quarter_offsets_t, DeviceInput, "unsigned int")),
      ("dev_permutation_station_t", DeviceOutput("dev_permutation_station_t", "unsigned int", self.__name)),
      ("dev_muon_hits_t", DeviceOutput("dev_muon_hits_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_muon_total_number_of_hits_t(self):
    return self.__ordered_parameters["host_muon_total_number_of_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_storage_tile_id_t(self):
    return self.__ordered_parameters["dev_storage_tile_id_t"]

  def dev_storage_tdc_value_t(self):
    return self.__ordered_parameters["dev_storage_tdc_value_t"]

  def dev_station_ocurrences_offset_t(self):
    return self.__ordered_parameters["dev_station_ocurrences_offset_t"]

  def dev_muon_compact_hit_t(self):
    return self.__ordered_parameters["dev_muon_compact_hit_t"]

  def dev_muon_raw_to_hits_t(self):
    return self.__ordered_parameters["dev_muon_raw_to_hits_t"]

  def dev_storage_station_region_quarter_offsets_t(self):
    return self.__ordered_parameters["dev_storage_station_region_quarter_offsets_t"]

  def dev_permutation_station_t(self):
    return self.__ordered_parameters["dev_permutation_station_t"]

  def dev_muon_hits_t(self):
    return self.__ordered_parameters["dev_muon_hits_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_populate_tile_and_tdc_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_muon_total_number_of_tiles_t",
    "dev_event_list_t",
    "dev_muon_raw_t",
    "dev_muon_raw_offsets_t",
    "dev_muon_raw_to_hits_t",
    "dev_storage_station_region_quarter_offsets_t",)
  outputs = (
    "dev_storage_tile_id_t",
    "dev_storage_tdc_value_t",
    "dev_atomics_muon_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "muon_populate_tile_and_tdc"

  def __init__(self,
    host_number_of_events_t,
    host_muon_total_number_of_tiles_t,
    dev_event_list_t,
    dev_muon_raw_t,
    dev_muon_raw_offsets_t,
    dev_muon_raw_to_hits_t,
    dev_storage_station_region_quarter_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="muon_populate_tile_and_tdc_t"):
    self.__filename = "device/muon/decoding/include/MuonPopulateTileAndTDC.cuh"
    self.__name = name
    self.__original_name = "muon_populate_tile_and_tdc_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_muon_total_number_of_tiles_t", check_input_parameter(host_muon_total_number_of_tiles_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_muon_raw_t", check_input_parameter(dev_muon_raw_t, DeviceInput, "char")),
      ("dev_muon_raw_offsets_t", check_input_parameter(dev_muon_raw_offsets_t, DeviceInput, "unsigned int")),
      ("dev_muon_raw_to_hits_t", check_input_parameter(dev_muon_raw_to_hits_t, DeviceInput, "int")),
      ("dev_storage_station_region_quarter_offsets_t", check_input_parameter(dev_storage_station_region_quarter_offsets_t, DeviceInput, "unsigned int")),
      ("dev_storage_tile_id_t", DeviceOutput("dev_storage_tile_id_t", "unsigned int", self.__name)),
      ("dev_storage_tdc_value_t", DeviceOutput("dev_storage_tdc_value_t", "unsigned int", self.__name)),
      ("dev_atomics_muon_t", DeviceOutput("dev_atomics_muon_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_muon_total_number_of_tiles_t(self):
    return self.__ordered_parameters["host_muon_total_number_of_tiles_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_muon_raw_t(self):
    return self.__ordered_parameters["dev_muon_raw_t"]

  def dev_muon_raw_offsets_t(self):
    return self.__ordered_parameters["dev_muon_raw_offsets_t"]

  def dev_muon_raw_to_hits_t(self):
    return self.__ordered_parameters["dev_muon_raw_to_hits_t"]

  def dev_storage_station_region_quarter_offsets_t(self):
    return self.__ordered_parameters["dev_storage_station_region_quarter_offsets_t"]

  def dev_storage_tile_id_t(self):
    return self.__ordered_parameters["dev_storage_tile_id_t"]

  def dev_storage_tdc_value_t(self):
    return self.__ordered_parameters["dev_storage_tdc_value_t"]

  def dev_atomics_muon_t(self):
    return self.__ordered_parameters["dev_atomics_muon_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class is_muon_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_station_ocurrences_offset_t",
    "dev_muon_hits_t",)
  outputs = (
    "dev_muon_track_occupancies_t",
    "dev_is_muon_t",)
  props = (
    "verbosity",
    "block_dim_x",)
  aggregates = ()
  namespace = "is_muon"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_station_ocurrences_offset_t,
    dev_muon_hits_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension X"),
    name="is_muon_t"):
    self.__filename = "device/muon/is_muon/include/IsMuon.cuh"
    self.__name = name
    self.__original_name = "is_muon_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number", check_input_parameter(dev_offsets_scifi_track_hit_number, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_station_ocurrences_offset_t", check_input_parameter(dev_station_ocurrences_offset_t, DeviceInput, "unsigned int")),
      ("dev_muon_hits_t", check_input_parameter(dev_muon_hits_t, DeviceInput, "char")),
      ("dev_muon_track_occupancies_t", DeviceOutput("dev_muon_track_occupancies_t", "int", self.__name)),
      ("dev_is_muon_t", DeviceOutput("dev_is_muon_t", "bool", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension X", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_station_ocurrences_offset_t(self):
    return self.__ordered_parameters["dev_station_ocurrences_offset_t"]

  def dev_muon_hits_t(self):
    return self.__ordered_parameters["dev_muon_hits_t"]

  def dev_muon_track_occupancies_t(self):
    return self.__ordered_parameters["dev_muon_track_occupancies_t"]

  def dev_is_muon_t(self):
    return self.__ordered_parameters["dev_is_muon_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_filter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_kalman_beamline_states_t",
    "dev_velo_track_hits_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_qop_t",
    "dev_ut_track_velo_indices_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_is_muon_t",
    "dev_kalman_pv_ipchi2_t",)
  outputs = (
    "host_selected_events_mf_t",
    "dev_mf_decisions_t",
    "dev_event_list_mf_t",
    "dev_selected_events_mf_t",
    "dev_mf_track_atomics_t",)
  props = (
    "verbosity",
    "mf_min_pt",
    "mf_min_ipchi2",
    "block_dim",)
  aggregates = ()
  namespace = "MuonFilter"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_kalman_beamline_states_t,
    dev_velo_track_hits_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_qop_t,
    dev_ut_track_velo_indices_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_is_muon_t,
    dev_kalman_pv_ipchi2_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    mf_min_pt=Property("float", "", "minimum track pT"),
    mf_min_ipchi2=Property("float", "", "minimum track IP chi2"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="muon_filter_t"):
    self.__filename = "device/muon/muon_filter/include/MuonFilter.cuh"
    self.__name = name
    self.__original_name = "muon_filter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_selected_events_mf_t", HostOutput("host_selected_events_mf_t", "unsigned int", self.__name)),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_beamline_states_t", check_input_parameter(dev_velo_kalman_beamline_states_t, DeviceInput, "char")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number", check_input_parameter(dev_offsets_scifi_track_hit_number, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_is_muon_t", check_input_parameter(dev_is_muon_t, DeviceInput, "bool")),
      ("dev_kalman_pv_ipchi2_t", check_input_parameter(dev_kalman_pv_ipchi2_t, DeviceInput, "char")),
      ("dev_mf_decisions_t", DeviceOutput("dev_mf_decisions_t", "unsigned int", self.__name)),
      ("dev_event_list_mf_t", DeviceOutput("dev_event_list_mf_t", "unsigned int", self.__name)),
      ("dev_selected_events_mf_t", DeviceOutput("dev_selected_events_mf_t", "unsigned int", self.__name)),
      ("dev_mf_track_atomics_t", DeviceOutput("dev_mf_track_atomics_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("mf_min_pt", Property("float", "", "minimum track pT", mf_min_pt)),
      ("mf_min_ipchi2", Property("float", "", "minimum track IP chi2", mf_min_ipchi2)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_selected_events_mf_t(self):
    return self.__ordered_parameters["host_selected_events_mf_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_is_muon_t(self):
    return self.__ordered_parameters["dev_is_muon_t"]

  def dev_kalman_pv_ipchi2_t(self):
    return self.__ordered_parameters["dev_kalman_pv_ipchi2_t"]

  def dev_mf_decisions_t(self):
    return self.__ordered_parameters["dev_mf_decisions_t"]

  def dev_event_list_mf_t(self):
    return self.__ordered_parameters["dev_event_list_mf_t"]

  def dev_selected_events_mf_t(self):
    return self.__ordered_parameters["dev_selected_events_mf_t"]

  def dev_mf_track_atomics_t(self):
    return self.__ordered_parameters["dev_mf_track_atomics_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def mf_min_pt(self):
    return self.__ordered_properties["mf_min_pt"]

  def mf_min_ipchi2(self):
    return self.__ordered_properties["mf_min_ipchi2"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class muon_catboost_features_extraction_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_atomics_scifi_t",
    "dev_scifi_track_hit_number_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_station_ocurrences_offset_t",
    "dev_muon_hits_t",
    "dev_event_list_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_muon_catboost_features_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "muon_catboost_features_extraction"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_atomics_scifi_t,
    dev_scifi_track_hit_number_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_station_ocurrences_offset_t,
    dev_muon_hits_t,
    dev_event_list_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="muon_catboost_features_extraction_t"):
    self.__filename = "device/muon/preprocessing/include/MuonFeaturesExtraction.cuh"
    self.__name = name
    self.__original_name = "muon_catboost_features_extraction_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_atomics_scifi_t", check_input_parameter(dev_atomics_scifi_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hit_number_t", check_input_parameter(dev_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_station_ocurrences_offset_t", check_input_parameter(dev_station_ocurrences_offset_t, DeviceInput, "unsigned int")),
      ("dev_muon_hits_t", check_input_parameter(dev_muon_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_muon_catboost_features_t", DeviceOutput("dev_muon_catboost_features_t", "float", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_atomics_scifi_t(self):
    return self.__ordered_parameters["dev_atomics_scifi_t"]

  def dev_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_scifi_track_hit_number_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_station_ocurrences_offset_t(self):
    return self.__ordered_parameters["dev_station_ocurrences_offset_t"]

  def dev_muon_hits_t(self):
    return self.__ordered_parameters["dev_muon_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_muon_catboost_features_t(self):
    return self.__ordered_parameters["dev_muon_catboost_features_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class dec_reporter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_active_lines_t",
    "dev_number_of_active_lines_t",
    "dev_selections_t",
    "dev_selections_offsets_t",)
  outputs = (
    "dev_dec_reports_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "dec_reporter"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_active_lines_t,
    dev_number_of_active_lines_t,
    dev_selections_t,
    dev_selections_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="dec_reporter_t"):
    self.__filename = "device/selections/Hlt1/include/DecReporter.cuh"
    self.__name = name
    self.__original_name = "dec_reporter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_active_lines_t", check_input_parameter(host_number_of_active_lines_t, HostInput, "unsigned int")),
      ("dev_number_of_active_lines_t", check_input_parameter(dev_number_of_active_lines_t, DeviceInput, "unsigned int")),
      ("dev_selections_t", check_input_parameter(dev_selections_t, DeviceInput, "bool")),
      ("dev_selections_offsets_t", check_input_parameter(dev_selections_offsets_t, DeviceInput, "unsigned int")),
      ("dev_dec_reports_t", DeviceOutput("dev_dec_reports_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_active_lines_t(self):
    return self.__ordered_parameters["host_number_of_active_lines_t"]

  def dev_number_of_active_lines_t(self):
    return self.__ordered_parameters["dev_number_of_active_lines_t"]

  def dev_selections_t(self):
    return self.__ordered_parameters["dev_selections_t"]

  def dev_selections_offsets_t(self):
    return self.__ordered_parameters["dev_selections_offsets_t"]

  def dev_dec_reports_t(self):
    return self.__ordered_parameters["dev_dec_reports_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class gather_selections_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_mep_layout_t",
    "dev_input_selections_t",
    "dev_input_selections_offsets_t",
    "host_input_post_scale_factors_t",
    "host_input_post_scale_hashes_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",)
  outputs = (
    "host_selections_lines_offsets_t",
    "host_selections_offsets_t",
    "host_number_of_active_lines_t",
    "host_names_of_active_lines_t",
    "dev_selections_t",
    "dev_selections_offsets_t",
    "dev_number_of_active_lines_t",
    "host_post_scale_factors_t",
    "host_post_scale_hashes_t",
    "dev_post_scale_factors_t",
    "dev_post_scale_hashes_t",)
  props = (
    "verbosity",
    "block_dim_x",
    "names_of_active_lines",)
  aggregates = (
    "dev_input_selections_t",
    "dev_input_selections_offsets_t",
    "host_input_post_scale_factors_t",
    "host_input_post_scale_hashes_t",)
  namespace = "gather_selections"

  def __init__(self,
    host_number_of_events_t,
    dev_mep_layout_t,
    dev_input_selections_t,
    dev_input_selections_offsets_t,
    host_input_post_scale_factors_t,
    host_input_post_scale_hashes_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension x"),
    names_of_active_lines=Property("int", "", "names of active lines"),
    name="gather_selections_t"):
    self.__filename = "device/selections/Hlt1/include/GatherSelections.cuh"
    self.__name = name
    self.__original_name = "gather_selections_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_selections_lines_offsets_t", HostOutput("host_selections_lines_offsets_t", "unsigned int", self.__name)),
      ("host_selections_offsets_t", HostOutput("host_selections_offsets_t", "unsigned int", self.__name)),
      ("host_number_of_active_lines_t", HostOutput("host_number_of_active_lines_t", "unsigned int", self.__name)),
      ("host_names_of_active_lines_t", HostOutput("host_names_of_active_lines_t", "char", self.__name)),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_input_selections_t", dev_input_selections_t),
      ("dev_input_selections_offsets_t", dev_input_selections_offsets_t),
      ("host_input_post_scale_factors_t", host_input_post_scale_factors_t),
      ("host_input_post_scale_hashes_t", host_input_post_scale_hashes_t),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_selections_t", DeviceOutput("dev_selections_t", "bool", self.__name)),
      ("dev_selections_offsets_t", DeviceOutput("dev_selections_offsets_t", "unsigned int", self.__name)),
      ("dev_number_of_active_lines_t", DeviceOutput("dev_number_of_active_lines_t", "unsigned int", self.__name)),
      ("host_post_scale_factors_t", HostOutput("host_post_scale_factors_t", "float", self.__name)),
      ("host_post_scale_hashes_t", HostOutput("host_post_scale_hashes_t", "int", self.__name)),
      ("dev_post_scale_factors_t", DeviceOutput("dev_post_scale_factors_t", "float", self.__name)),
      ("dev_post_scale_hashes_t", DeviceOutput("dev_post_scale_hashes_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension x", block_dim_x)),
      ("names_of_active_lines", Property("int", "", "names of active lines", names_of_active_lines))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_selections_lines_offsets_t(self):
    return self.__ordered_parameters["host_selections_lines_offsets_t"]

  def host_selections_offsets_t(self):
    return self.__ordered_parameters["host_selections_offsets_t"]

  def host_number_of_active_lines_t(self):
    return self.__ordered_parameters["host_number_of_active_lines_t"]

  def host_names_of_active_lines_t(self):
    return self.__ordered_parameters["host_names_of_active_lines_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_input_selections_t(self):
    return self.__ordered_parameters["dev_input_selections_t"]

  def dev_input_selections_offsets_t(self):
    return self.__ordered_parameters["dev_input_selections_offsets_t"]

  def host_input_post_scale_factors_t(self):
    return self.__ordered_parameters["host_input_post_scale_factors_t"]

  def host_input_post_scale_hashes_t(self):
    return self.__ordered_parameters["host_input_post_scale_hashes_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_selections_t(self):
    return self.__ordered_parameters["dev_selections_t"]

  def dev_selections_offsets_t(self):
    return self.__ordered_parameters["dev_selections_offsets_t"]

  def dev_number_of_active_lines_t(self):
    return self.__ordered_parameters["dev_number_of_active_lines_t"]

  def host_post_scale_factors_t(self):
    return self.__ordered_parameters["host_post_scale_factors_t"]

  def host_post_scale_hashes_t(self):
    return self.__ordered_parameters["host_post_scale_hashes_t"]

  def dev_post_scale_factors_t(self):
    return self.__ordered_parameters["dev_post_scale_factors_t"]

  def dev_post_scale_hashes_t(self):
    return self.__ordered_parameters["dev_post_scale_hashes_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def names_of_active_lines(self):
    return self.__ordered_properties["names_of_active_lines"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class global_decision_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_active_lines_t",
    "dev_number_of_events_t",
    "dev_number_of_active_lines_t",
    "dev_dec_reports_t",)
  outputs = (
    "dev_global_decision_t",)
  props = (
    "verbosity",
    "block_dim_x",)
  aggregates = ()
  namespace = "global_decision"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_active_lines_t,
    dev_number_of_events_t,
    dev_number_of_active_lines_t,
    dev_dec_reports_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension X"),
    name="global_decision_t"):
    self.__filename = "device/selections/Hlt1/include/GlobalDecision.cuh"
    self.__name = name
    self.__original_name = "global_decision_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_active_lines_t", check_input_parameter(host_number_of_active_lines_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_number_of_active_lines_t", check_input_parameter(dev_number_of_active_lines_t, DeviceInput, "unsigned int")),
      ("dev_dec_reports_t", check_input_parameter(dev_dec_reports_t, DeviceInput, "unsigned int")),
      ("dev_global_decision_t", DeviceOutput("dev_global_decision_t", "bool", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension X", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_active_lines_t(self):
    return self.__ordered_parameters["host_number_of_active_lines_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_number_of_active_lines_t(self):
    return self.__ordered_parameters["dev_number_of_active_lines_t"]

  def dev_dec_reports_t(self):
    return self.__ordered_parameters["dev_dec_reports_t"]

  def dev_global_decision_t(self):
    return self.__ordered_parameters["dev_global_decision_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class d2kpi_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minComboPt",
    "mPi",
    "mK",
    "mD",
    "maxVertexChi2",
    "minEta",
    "maxEta",
    "minTrackPt",
    "massWindow",
    "minTrackIPChi2",)
  aggregates = ()
  namespace = "d2kpi_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minComboPt=Property("float", "", "minComboPt description"),
    mPi=Property("float", "", "mPi description"),
    mK=Property("float", "", "mK description"),
    mD=Property("float", "", "mD description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minEta=Property("float", "", "minEta description"),
    maxEta=Property("float", "", "maxEta description"),
    minTrackPt=Property("float", "", "minTrackPt description"),
    massWindow=Property("float", "", "massWindow description"),
    minTrackIPChi2=Property("float", "", "minTrackIPChi2 description"),
    name="d2kpi_line_t"):
    self.__filename = "device/selections/lines/calibration/include/D2KPiLine.cuh"
    self.__name = name
    self.__original_name = "d2kpi_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minComboPt", Property("float", "", "minComboPt description", minComboPt)),
      ("mPi", Property("float", "", "mPi description", mPi)),
      ("mK", Property("float", "", "mK description", mK)),
      ("mD", Property("float", "", "mD description", mD)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minEta", Property("float", "", "minEta description", minEta)),
      ("maxEta", Property("float", "", "maxEta description", maxEta)),
      ("minTrackPt", Property("float", "", "minTrackPt description", minTrackPt)),
      ("massWindow", Property("float", "", "massWindow description", massWindow)),
      ("minTrackIPChi2", Property("float", "", "minTrackIPChi2 description", minTrackIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minComboPt(self):
    return self.__ordered_properties["minComboPt"]

  def mPi(self):
    return self.__ordered_properties["mPi"]

  def mK(self):
    return self.__ordered_properties["mK"]

  def mD(self):
    return self.__ordered_properties["mD"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minEta(self):
    return self.__ordered_properties["minEta"]

  def maxEta(self):
    return self.__ordered_properties["maxEta"]

  def minTrackPt(self):
    return self.__ordered_properties["minTrackPt"]

  def massWindow(self):
    return self.__ordered_properties["massWindow"]

  def minTrackIPChi2(self):
    return self.__ordered_properties["minTrackIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class passthrough_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_number_of_events_t",
    "dev_event_list_t",
    "dev_offsets_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",)
  aggregates = ()
  namespace = "passthrough_line"

  def __init__(self,
    host_number_of_events_t,
    dev_number_of_events_t,
    dev_event_list_t,
    dev_offsets_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    name="passthrough_line_t"):
    self.__filename = "device/selections/lines/calibration/include/PassthroughLine.cuh"
    self.__name = name
    self.__original_name = "passthrough_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_tracks_t", check_input_parameter(dev_offsets_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_offsets_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class d2kk_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minComboPt",
    "mK",
    "mD",
    "maxVertexChi2",
    "minEta",
    "maxEta",
    "minTrackPt",
    "massWindow",
    "minTrackIPChi2",)
  aggregates = ()
  namespace = "d2kk_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minComboPt=Property("float", "", "minComboPt description"),
    mK=Property("float", "", "mK description"),
    mD=Property("float", "", "mD description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minEta=Property("float", "", "minEta description"),
    maxEta=Property("float", "", "maxEta description"),
    minTrackPt=Property("float", "", "minTrackPt description"),
    massWindow=Property("float", "", "massWindow description"),
    minTrackIPChi2=Property("float", "", "minTrackIPChi2 description"),
    name="d2kk_line_t"):
    self.__filename = "device/selections/lines/charm/include/D2KKLine.cuh"
    self.__name = name
    self.__original_name = "d2kk_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minComboPt", Property("float", "", "minComboPt description", minComboPt)),
      ("mK", Property("float", "", "mK description", mK)),
      ("mD", Property("float", "", "mD description", mD)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minEta", Property("float", "", "minEta description", minEta)),
      ("maxEta", Property("float", "", "maxEta description", maxEta)),
      ("minTrackPt", Property("float", "", "minTrackPt description", minTrackPt)),
      ("massWindow", Property("float", "", "massWindow description", massWindow)),
      ("minTrackIPChi2", Property("float", "", "minTrackIPChi2 description", minTrackIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minComboPt(self):
    return self.__ordered_properties["minComboPt"]

  def mK(self):
    return self.__ordered_properties["mK"]

  def mD(self):
    return self.__ordered_properties["mD"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minEta(self):
    return self.__ordered_properties["minEta"]

  def maxEta(self):
    return self.__ordered_properties["maxEta"]

  def minTrackPt(self):
    return self.__ordered_properties["minTrackPt"]

  def massWindow(self):
    return self.__ordered_properties["massWindow"]

  def minTrackIPChi2(self):
    return self.__ordered_properties["minTrackIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class d2pipi_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "mPi",
    "mD",
    "minComboPt",
    "maxVertexChi2",
    "minEta",
    "maxEta",
    "minTrackPt",
    "massWindow",
    "minTrackIPChi2",)
  aggregates = ()
  namespace = "d2pipi_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    mPi=Property("float", "", "mPi description"),
    mD=Property("float", "", "mD description"),
    minComboPt=Property("float", "", "minComboPt description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minEta=Property("float", "", "minEta description"),
    maxEta=Property("float", "", "maxEta description"),
    minTrackPt=Property("float", "", "minTrackPt description"),
    massWindow=Property("float", "", "massWindow description"),
    minTrackIPChi2=Property("float", "", "minTrackIPChi2 description"),
    name="d2pipi_line_t"):
    self.__filename = "device/selections/lines/charm/include/D2PiPiLine.cuh"
    self.__name = name
    self.__original_name = "d2pipi_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("mPi", Property("float", "", "mPi description", mPi)),
      ("mD", Property("float", "", "mD description", mD)),
      ("minComboPt", Property("float", "", "minComboPt description", minComboPt)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minEta", Property("float", "", "minEta description", minEta)),
      ("maxEta", Property("float", "", "maxEta description", maxEta)),
      ("minTrackPt", Property("float", "", "minTrackPt description", minTrackPt)),
      ("massWindow", Property("float", "", "massWindow description", massWindow)),
      ("minTrackIPChi2", Property("float", "", "minTrackIPChi2 description", minTrackIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def mPi(self):
    return self.__ordered_properties["mPi"]

  def mD(self):
    return self.__ordered_properties["mD"]

  def minComboPt(self):
    return self.__ordered_properties["minComboPt"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minEta(self):
    return self.__ordered_properties["minEta"]

  def maxEta(self):
    return self.__ordered_properties["maxEta"]

  def minTrackPt(self):
    return self.__ordered_properties["minTrackPt"]

  def massWindow(self):
    return self.__ordered_properties["massWindow"]

  def minTrackIPChi2(self):
    return self.__ordered_properties["minTrackIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class track_mva_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_tracks_t",
    "dev_track_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "maxChi2Ndof",
    "minPt",
    "maxPt",
    "minIPChi2",
    "param1",
    "param2",
    "param3",
    "alpha",)
  aggregates = ()
  namespace = "track_mva_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_tracks_t,
    dev_track_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    maxChi2Ndof=Property("float", "", "maxChi2Ndof description"),
    minPt=Property("float", "", "minPt description"),
    maxPt=Property("float", "", "maxPt description"),
    minIPChi2=Property("float", "", "minIPChi2 description"),
    param1=Property("float", "", "param1 description"),
    param2=Property("float", "", "param2 description"),
    param3=Property("float", "", "param3 description"),
    alpha=Property("float", "", "alpha description"),
    name="track_mva_line_t"):
    self.__filename = "device/selections/lines/inclusive_hadron/include/TrackMVALine.cuh"
    self.__name = name
    self.__original_name = "track_mva_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_track_offsets_t", check_input_parameter(dev_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("maxChi2Ndof", Property("float", "", "maxChi2Ndof description", maxChi2Ndof)),
      ("minPt", Property("float", "", "minPt description", minPt)),
      ("maxPt", Property("float", "", "maxPt description", maxPt)),
      ("minIPChi2", Property("float", "", "minIPChi2 description", minIPChi2)),
      ("param1", Property("float", "", "param1 description", param1)),
      ("param2", Property("float", "", "param2 description", param2)),
      ("param3", Property("float", "", "param3 description", param3)),
      ("alpha", Property("float", "", "alpha description", alpha))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_track_offsets_t(self):
    return self.__ordered_parameters["dev_track_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def maxChi2Ndof(self):
    return self.__ordered_properties["maxChi2Ndof"]

  def minPt(self):
    return self.__ordered_properties["minPt"]

  def maxPt(self):
    return self.__ordered_properties["maxPt"]

  def minIPChi2(self):
    return self.__ordered_properties["minIPChi2"]

  def param1(self):
    return self.__ordered_properties["param1"]

  def param2(self):
    return self.__ordered_properties["param2"]

  def param3(self):
    return self.__ordered_properties["param3"]

  def alpha(self):
    return self.__ordered_properties["alpha"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class two_track_mva_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minComboPt",
    "maxVertexChi2",
    "minMCor",
    "minEta",
    "maxEta",
    "minTrackPt",
    "maxNTrksAssoc",
    "minFDChi2",
    "minTrackIPChi2",)
  aggregates = ()
  namespace = "two_track_mva_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minComboPt=Property("float", "", "minComboPt description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minMCor=Property("float", "", "minMCor description"),
    minEta=Property("float", "", "minEta description"),
    maxEta=Property("float", "", "maxEta description"),
    minTrackPt=Property("float", "", "minTrackPt description"),
    maxNTrksAssoc=Property("int", "", "maxNTrksAssoc description"),
    minFDChi2=Property("float", "", "minFDChi2 description"),
    minTrackIPChi2=Property("float", "", "minTrackIPChi2 description"),
    name="two_track_mva_line_t"):
    self.__filename = "device/selections/lines/inclusive_hadron/include/TwoTrackMVALine.cuh"
    self.__name = name
    self.__original_name = "two_track_mva_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minComboPt", Property("float", "", "minComboPt description", minComboPt)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minMCor", Property("float", "", "minMCor description", minMCor)),
      ("minEta", Property("float", "", "minEta description", minEta)),
      ("maxEta", Property("float", "", "maxEta description", maxEta)),
      ("minTrackPt", Property("float", "", "minTrackPt description", minTrackPt)),
      ("maxNTrksAssoc", Property("int", "", "maxNTrksAssoc description", maxNTrksAssoc)),
      ("minFDChi2", Property("float", "", "minFDChi2 description", minFDChi2)),
      ("minTrackIPChi2", Property("float", "", "minTrackIPChi2 description", minTrackIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minComboPt(self):
    return self.__ordered_properties["minComboPt"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minMCor(self):
    return self.__ordered_properties["minMCor"]

  def minEta(self):
    return self.__ordered_properties["minEta"]

  def maxEta(self):
    return self.__ordered_properties["maxEta"]

  def minTrackPt(self):
    return self.__ordered_properties["minTrackPt"]

  def maxNTrksAssoc(self):
    return self.__ordered_properties["maxNTrksAssoc"]

  def minFDChi2(self):
    return self.__ordered_properties["minFDChi2"]

  def minTrackIPChi2(self):
    return self.__ordered_properties["minTrackIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class beam_crossing_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_mep_layout_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "beam_crossing_type",)
  aggregates = ()
  namespace = "beam_crossing_line"

  def __init__(self,
    host_number_of_events_t,
    dev_mep_layout_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    beam_crossing_type=Property("unsigned int", "", "ODIN beam crossing type [0-3]"),
    name="beam_crossing_line_t"):
    self.__filename = "device/selections/lines/monitoring/include/BeamCrossingLine.cuh"
    self.__name = name
    self.__original_name = "beam_crossing_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("beam_crossing_type", Property("unsigned int", "", "ODIN beam crossing type [0-3]", beam_crossing_type))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def beam_crossing_type(self):
    return self.__ordered_properties["beam_crossing_type"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class odin_event_type_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_mep_layout_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "odin_event_type",)
  aggregates = ()
  namespace = "odin_event_type_line"

  def __init__(self,
    host_number_of_events_t,
    dev_mep_layout_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    odin_event_type=Property("unsigned int", "", "ODIN event type"),
    name="odin_event_type_line_t"):
    self.__filename = "device/selections/lines/monitoring/include/ODINEventTypeLine.cuh"
    self.__name = name
    self.__original_name = "odin_event_type_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("odin_event_type", Property("unsigned int", "", "ODIN event type", odin_event_type))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def odin_event_type(self):
    return self.__ordered_properties["odin_event_type"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_micro_bias_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_number_of_events_t",
    "dev_event_list_t",
    "dev_offsets_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "min_velo_tracks",)
  aggregates = ()
  namespace = "velo_micro_bias_line"

  def __init__(self,
    host_number_of_events_t,
    dev_number_of_events_t,
    dev_event_list_t,
    dev_offsets_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    min_velo_tracks=Property("unsigned int", "", "Minimum number of VELO tracks"),
    name="velo_micro_bias_line_t"):
    self.__filename = "device/selections/lines/monitoring/include/VeloMicroBiasLine.cuh"
    self.__name = name
    self.__original_name = "velo_micro_bias_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_tracks_t", check_input_parameter(dev_offsets_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("min_velo_tracks", Property("unsigned int", "", "Minimum number of VELO tracks", min_velo_tracks))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_offsets_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def min_velo_tracks(self):
    return self.__ordered_properties["min_velo_tracks"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class di_muon_mass_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minHighMassTrackPt",
    "minHighMassTrackP",
    "minMass",
    "maxDoca",
    "maxVertexChi2",
    "minIPChi2",)
  aggregates = ()
  namespace = "di_muon_mass_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minHighMassTrackPt=Property("float", "", "minHighMassTrackPt description"),
    minHighMassTrackP=Property("float", "", "minHighMassTrackP description"),
    minMass=Property("float", "", "minMass description"),
    maxDoca=Property("float", "", "maxDoca description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minIPChi2=Property("float", "", "minIPChi2 description"),
    name="di_muon_mass_line_t"):
    self.__filename = "device/selections/lines/muon/include/DiMuonMassLine.cuh"
    self.__name = name
    self.__original_name = "di_muon_mass_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minHighMassTrackPt", Property("float", "", "minHighMassTrackPt description", minHighMassTrackPt)),
      ("minHighMassTrackP", Property("float", "", "minHighMassTrackP description", minHighMassTrackP)),
      ("minMass", Property("float", "", "minMass description", minMass)),
      ("maxDoca", Property("float", "", "maxDoca description", maxDoca)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minIPChi2", Property("float", "", "minIPChi2 description", minIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minHighMassTrackPt(self):
    return self.__ordered_properties["minHighMassTrackPt"]

  def minHighMassTrackP(self):
    return self.__ordered_properties["minHighMassTrackP"]

  def minMass(self):
    return self.__ordered_properties["minMass"]

  def maxDoca(self):
    return self.__ordered_properties["maxDoca"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minIPChi2(self):
    return self.__ordered_properties["minIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class di_muon_soft_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "DMSoftM0",
    "DMSoftM1",
    "DMSoftM2",
    "DMSoftMinIPChi2",
    "DMSoftMinRho2",
    "DMSoftMinZ",
    "DMSoftMaxZ",
    "DMSoftMaxDOCA",
    "DMSoftMaxIPDZ",
    "DMSoftGhost",)
  aggregates = ()
  namespace = "di_muon_soft_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    DMSoftM0=Property("float", "", "DMSoftM0 description"),
    DMSoftM1=Property("float", "", "DMSoftM1 description"),
    DMSoftM2=Property("float", "", "DMSoftM2 description"),
    DMSoftMinIPChi2=Property("float", "", "DMSoftMinIPChi2 description"),
    DMSoftMinRho2=Property("float", "", "DMSoftMinRho2 description"),
    DMSoftMinZ=Property("float", "", "DMSoftMinZ description"),
    DMSoftMaxZ=Property("float", "", "DMSoftMaxZ description"),
    DMSoftMaxDOCA=Property("float", "", "DMSoftMaxDOCA description"),
    DMSoftMaxIPDZ=Property("float", "", "DMSoftMaxIPDZ description"),
    DMSoftGhost=Property("float", "", "DMSoftGhost description"),
    name="di_muon_soft_line_t"):
    self.__filename = "device/selections/lines/muon/include/DiMuonSoftLine.cuh"
    self.__name = name
    self.__original_name = "di_muon_soft_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("DMSoftM0", Property("float", "", "DMSoftM0 description", DMSoftM0)),
      ("DMSoftM1", Property("float", "", "DMSoftM1 description", DMSoftM1)),
      ("DMSoftM2", Property("float", "", "DMSoftM2 description", DMSoftM2)),
      ("DMSoftMinIPChi2", Property("float", "", "DMSoftMinIPChi2 description", DMSoftMinIPChi2)),
      ("DMSoftMinRho2", Property("float", "", "DMSoftMinRho2 description", DMSoftMinRho2)),
      ("DMSoftMinZ", Property("float", "", "DMSoftMinZ description", DMSoftMinZ)),
      ("DMSoftMaxZ", Property("float", "", "DMSoftMaxZ description", DMSoftMaxZ)),
      ("DMSoftMaxDOCA", Property("float", "", "DMSoftMaxDOCA description", DMSoftMaxDOCA)),
      ("DMSoftMaxIPDZ", Property("float", "", "DMSoftMaxIPDZ description", DMSoftMaxIPDZ)),
      ("DMSoftGhost", Property("float", "", "DMSoftGhost description", DMSoftGhost))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def DMSoftM0(self):
    return self.__ordered_properties["DMSoftM0"]

  def DMSoftM1(self):
    return self.__ordered_properties["DMSoftM1"]

  def DMSoftM2(self):
    return self.__ordered_properties["DMSoftM2"]

  def DMSoftMinIPChi2(self):
    return self.__ordered_properties["DMSoftMinIPChi2"]

  def DMSoftMinRho2(self):
    return self.__ordered_properties["DMSoftMinRho2"]

  def DMSoftMinZ(self):
    return self.__ordered_properties["DMSoftMinZ"]

  def DMSoftMaxZ(self):
    return self.__ordered_properties["DMSoftMaxZ"]

  def DMSoftMaxDOCA(self):
    return self.__ordered_properties["DMSoftMaxDOCA"]

  def DMSoftMaxIPDZ(self):
    return self.__ordered_properties["DMSoftMaxIPDZ"]

  def DMSoftGhost(self):
    return self.__ordered_properties["DMSoftGhost"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class di_muon_track_eff_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "DMTrackEffM0",
    "DMTrackEffM1",)
  aggregates = ()
  namespace = "di_muon_track_eff_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    DMTrackEffM0=Property("float", "", "DMTrackEffM0 description"),
    DMTrackEffM1=Property("float", "", "DMTrackEffM1 description"),
    name="di_muon_track_eff_line_t"):
    self.__filename = "device/selections/lines/muon/include/DiMuonTrackEffLine.cuh"
    self.__name = name
    self.__original_name = "di_muon_track_eff_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("DMTrackEffM0", Property("float", "", "DMTrackEffM0 description", DMTrackEffM0)),
      ("DMTrackEffM1", Property("float", "", "DMTrackEffM1 description", DMTrackEffM1))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def DMTrackEffM0(self):
    return self.__ordered_properties["DMTrackEffM0"]

  def DMTrackEffM1(self):
    return self.__ordered_properties["DMTrackEffM1"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class displaced_di_muon_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minDispTrackPt",
    "maxVertexChi2",
    "dispMinIPChi2",
    "dispMinEta",
    "dispMaxEta",)
  aggregates = ()
  namespace = "displaced_di_muon_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minDispTrackPt=Property("float", "", "minDispTrackPt description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    dispMinIPChi2=Property("float", "", "dispMinIPChi2 description"),
    dispMinEta=Property("float", "", "dispMinEta description"),
    dispMaxEta=Property("float", "", "dispMaxEta description"),
    name="displaced_di_muon_line_t"):
    self.__filename = "device/selections/lines/muon/include/DisplacedDiMuonLine.cuh"
    self.__name = name
    self.__original_name = "displaced_di_muon_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minDispTrackPt", Property("float", "", "minDispTrackPt description", minDispTrackPt)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("dispMinIPChi2", Property("float", "", "dispMinIPChi2 description", dispMinIPChi2)),
      ("dispMinEta", Property("float", "", "dispMinEta description", dispMinEta)),
      ("dispMaxEta", Property("float", "", "dispMaxEta description", dispMaxEta))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minDispTrackPt(self):
    return self.__ordered_properties["minDispTrackPt"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def dispMinIPChi2(self):
    return self.__ordered_properties["dispMinIPChi2"]

  def dispMinEta(self):
    return self.__ordered_properties["dispMinEta"]

  def dispMaxEta(self):
    return self.__ordered_properties["dispMaxEta"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class low_pt_di_muon_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_svs_t",
    "dev_sv_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "minTrackIP",
    "minTrackPt",
    "minTrackP",
    "minTrackIPChi2",
    "maxDOCA",
    "maxVertexChi2",
    "minMass",)
  aggregates = ()
  namespace = "low_pt_di_muon_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_svs_t,
    dev_sv_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    minTrackIP=Property("float", "", "minTrackIP description"),
    minTrackPt=Property("float", "", "minTrackPt description"),
    minTrackP=Property("float", "", "minTrackP description"),
    minTrackIPChi2=Property("float", "", "minTrackIPChi2 description"),
    maxDOCA=Property("float", "", "maxDOCA description"),
    maxVertexChi2=Property("float", "", "maxVertexChi2 description"),
    minMass=Property("float", "", "minMass description"),
    name="low_pt_di_muon_line_t"):
    self.__filename = "device/selections/lines/muon/include/LowPtDiMuonLine.cuh"
    self.__name = name
    self.__original_name = "low_pt_di_muon_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_svs_t", check_input_parameter(dev_svs_t, DeviceInput, "int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("minTrackIP", Property("float", "", "minTrackIP description", minTrackIP)),
      ("minTrackPt", Property("float", "", "minTrackPt description", minTrackPt)),
      ("minTrackP", Property("float", "", "minTrackP description", minTrackP)),
      ("minTrackIPChi2", Property("float", "", "minTrackIPChi2 description", minTrackIPChi2)),
      ("maxDOCA", Property("float", "", "maxDOCA description", maxDOCA)),
      ("maxVertexChi2", Property("float", "", "maxVertexChi2 description", maxVertexChi2)),
      ("minMass", Property("float", "", "minMass description", minMass))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_svs_t(self):
    return self.__ordered_parameters["dev_svs_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def minTrackIP(self):
    return self.__ordered_properties["minTrackIP"]

  def minTrackPt(self):
    return self.__ordered_properties["minTrackPt"]

  def minTrackP(self):
    return self.__ordered_properties["minTrackP"]

  def minTrackIPChi2(self):
    return self.__ordered_properties["minTrackIPChi2"]

  def maxDOCA(self):
    return self.__ordered_properties["maxDOCA"]

  def maxVertexChi2(self):
    return self.__ordered_properties["maxVertexChi2"]

  def minMass(self):
    return self.__ordered_properties["minMass"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class low_pt_muon_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_tracks_t",
    "dev_track_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "maxChi2Ndof",
    "minPt",
    "minIP",
    "minIPChi2",)
  aggregates = ()
  namespace = "low_pt_muon_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_tracks_t,
    dev_track_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    maxChi2Ndof=Property("float", "", "maxChi2Ndof description"),
    minPt=Property("float", "", "minPt description"),
    minIP=Property("float", "", "minIP description"),
    minIPChi2=Property("float", "", "minIPChi2 description"),
    name="low_pt_muon_line_t"):
    self.__filename = "device/selections/lines/muon/include/LowPtMuonLine.cuh"
    self.__name = name
    self.__original_name = "low_pt_muon_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_track_offsets_t", check_input_parameter(dev_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("maxChi2Ndof", Property("float", "", "maxChi2Ndof description", maxChi2Ndof)),
      ("minPt", Property("float", "", "minPt description", minPt)),
      ("minIP", Property("float", "", "minIP description", minIP)),
      ("minIPChi2", Property("float", "", "minIPChi2 description", minIPChi2))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_track_offsets_t(self):
    return self.__ordered_parameters["dev_track_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def maxChi2Ndof(self):
    return self.__ordered_properties["maxChi2Ndof"]

  def minPt(self):
    return self.__ordered_properties["minPt"]

  def minIP(self):
    return self.__ordered_properties["minIP"]

  def minIPChi2(self):
    return self.__ordered_properties["minIPChi2"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class single_high_pt_muon_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_tracks_t",
    "dev_track_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "maxChi2Ndof",
    "singleMinPt",
    "singleMinP",)
  aggregates = ()
  namespace = "single_high_pt_muon_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_tracks_t,
    dev_track_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    maxChi2Ndof=Property("float", "", "maxChi2Ndof description"),
    singleMinPt=Property("float", "", "singleMinPt description"),
    singleMinP=Property("float", "", "singleMinP description"),
    name="single_high_pt_muon_line_t"):
    self.__filename = "device/selections/lines/muon/include/SingleHighPtMuonLine.cuh"
    self.__name = name
    self.__original_name = "single_high_pt_muon_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_track_offsets_t", check_input_parameter(dev_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("maxChi2Ndof", Property("float", "", "maxChi2Ndof description", maxChi2Ndof)),
      ("singleMinPt", Property("float", "", "singleMinPt description", singleMinPt)),
      ("singleMinP", Property("float", "", "singleMinP description", singleMinP))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_track_offsets_t(self):
    return self.__ordered_parameters["dev_track_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def maxChi2Ndof(self):
    return self.__ordered_properties["maxChi2Ndof"]

  def singleMinPt(self):
    return self.__ordered_properties["singleMinPt"]

  def singleMinP(self):
    return self.__ordered_properties["singleMinP"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class track_muon_mva_line_t(SelectionAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_reconstructed_scifi_tracks_t",
    "dev_tracks_t",
    "dev_track_offsets_t",
    "dev_event_list_t",
    "dev_odin_raw_input_t",
    "dev_odin_raw_input_offsets_t",
    "dev_mep_layout_t",)
  outputs = (
    "dev_decisions_t",
    "dev_decisions_offsets_t",
    "host_post_scaler_t",
    "host_post_scaler_hash_t",)
  props = (
    "verbosity",
    "pre_scaler",
    "post_scaler",
    "pre_scaler_hash_string",
    "post_scaler_hash_string",
    "maxChi2Ndof",
    "minPt",
    "maxPt",
    "minIPChi2",
    "param1",
    "param2",
    "param3",
    "alpha",)
  aggregates = ()
  namespace = "track_muon_mva_line"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_reconstructed_scifi_tracks_t,
    dev_tracks_t,
    dev_track_offsets_t,
    dev_event_list_t,
    dev_odin_raw_input_t,
    dev_odin_raw_input_offsets_t,
    dev_mep_layout_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    pre_scaler=Property("float", "", "Pre-scaling factor"),
    post_scaler=Property("float", "", "Post-scaling factor"),
    pre_scaler_hash_string=Property("int", "", "Pre-scaling hash string"),
    post_scaler_hash_string=Property("int", "", "Post-scaling hash string"),
    maxChi2Ndof=Property("float", "", "maxChi2Ndof description"),
    minPt=Property("float", "", "minPt description"),
    maxPt=Property("float", "", "maxPt description"),
    minIPChi2=Property("float", "", "minIPChi2 description"),
    param1=Property("float", "", "param1 description"),
    param2=Property("float", "", "param2 description"),
    param3=Property("float", "", "param3 description"),
    alpha=Property("float", "", "alpha description"),
    name="track_muon_mva_line_t"):
    self.__filename = "device/selections/lines/muon/include/TrackMuonMVALine.cuh"
    self.__name = name
    self.__original_name = "track_muon_mva_line_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_scifi_tracks_t", check_input_parameter(host_number_of_reconstructed_scifi_tracks_t, HostInput, "unsigned int")),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_track_offsets_t", check_input_parameter(dev_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_odin_raw_input_t", check_input_parameter(dev_odin_raw_input_t, DeviceInput, "char")),
      ("dev_odin_raw_input_offsets_t", check_input_parameter(dev_odin_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mep_layout_t", check_input_parameter(dev_mep_layout_t, DeviceInput, "unsigned int")),
      ("dev_decisions_t", DeviceOutput("dev_decisions_t", "bool", self.__name)),
      ("dev_decisions_offsets_t", DeviceOutput("dev_decisions_offsets_t", "unsigned int", self.__name)),
      ("host_post_scaler_t", HostOutput("host_post_scaler_t", "float", self.__name)),
      ("host_post_scaler_hash_t", HostOutput("host_post_scaler_hash_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("pre_scaler", Property("float", "", "Pre-scaling factor", pre_scaler)),
      ("post_scaler", Property("float", "", "Post-scaling factor", post_scaler)),
      ("pre_scaler_hash_string", Property("int", "", "Pre-scaling hash string", pre_scaler_hash_string)),
      ("post_scaler_hash_string", Property("int", "", "Post-scaling hash string", post_scaler_hash_string)),
      ("maxChi2Ndof", Property("float", "", "maxChi2Ndof description", maxChi2Ndof)),
      ("minPt", Property("float", "", "minPt description", minPt)),
      ("maxPt", Property("float", "", "maxPt description", maxPt)),
      ("minIPChi2", Property("float", "", "minIPChi2 description", minIPChi2)),
      ("param1", Property("float", "", "param1 description", param1)),
      ("param2", Property("float", "", "param2 description", param2)),
      ("param3", Property("float", "", "param3 description", param3)),
      ("alpha", Property("float", "", "alpha description", alpha))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_reconstructed_scifi_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_scifi_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_track_offsets_t(self):
    return self.__ordered_parameters["dev_track_offsets_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_odin_raw_input_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_t"]

  def dev_odin_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_odin_raw_input_offsets_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def dev_decisions_t(self):
    return self.__ordered_parameters["dev_decisions_t"]

  def dev_decisions_offsets_t(self):
    return self.__ordered_parameters["dev_decisions_offsets_t"]

  def host_post_scaler_t(self):
    return self.__ordered_parameters["host_post_scaler_t"]

  def host_post_scaler_hash_t(self):
    return self.__ordered_parameters["host_post_scaler_hash_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def pre_scaler(self):
    return self.__ordered_properties["pre_scaler"]

  def post_scaler(self):
    return self.__ordered_properties["post_scaler"]

  def pre_scaler_hash_string(self):
    return self.__ordered_properties["pre_scaler_hash_string"]

  def post_scaler_hash_string(self):
    return self.__ordered_properties["post_scaler_hash_string"]

  def maxChi2Ndof(self):
    return self.__ordered_properties["maxChi2Ndof"]

  def minPt(self):
    return self.__ordered_properties["minPt"]

  def maxPt(self):
    return self.__ordered_properties["maxPt"]

  def minIPChi2(self):
    return self.__ordered_properties["minIPChi2"]

  def param1(self):
    return self.__ordered_properties["param1"]

  def param2(self):
    return self.__ordered_properties["param2"]

  def param3(self):
    return self.__ordered_properties["param3"]

  def alpha(self):
    return self.__ordered_properties["alpha"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_calculate_phi_and_sort_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_total_number_of_velo_clusters_t",
    "dev_event_list_t",
    "dev_offsets_estimated_input_size_t",
    "dev_module_cluster_num_t",
    "dev_velo_cluster_container_t",
    "dev_number_of_events_t",
    "dev_velo_clusters_t",)
  outputs = (
    "dev_sorted_velo_cluster_container_t",
    "dev_hit_permutation_t",
    "dev_hit_phi_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_calculate_phi_and_sort"

  def __init__(self,
    host_number_of_events_t,
    host_total_number_of_velo_clusters_t,
    dev_event_list_t,
    dev_offsets_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_velo_cluster_container_t,
    dev_number_of_events_t,
    dev_velo_clusters_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_calculate_phi_and_sort_t"):
    self.__filename = "device/velo/calculate_phi_and_sort/include/CalculatePhiAndSort.cuh"
    self.__name = name
    self.__original_name = "velo_calculate_phi_and_sort_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_total_number_of_velo_clusters_t", check_input_parameter(host_total_number_of_velo_clusters_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_offsets_estimated_input_size_t", check_input_parameter(dev_offsets_estimated_input_size_t, DeviceInput, "unsigned int")),
      ("dev_module_cluster_num_t", check_input_parameter(dev_module_cluster_num_t, DeviceInput, "unsigned int")),
      ("dev_velo_cluster_container_t", check_input_parameter(dev_velo_cluster_container_t, DeviceInput, "char")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_sorted_velo_cluster_container_t", DeviceOutput("dev_sorted_velo_cluster_container_t", "char", self.__name)),
      ("dev_hit_permutation_t", DeviceOutput("dev_hit_permutation_t", "unsigned int", self.__name)),
      ("dev_hit_phi_t", DeviceOutput("dev_hit_phi_t", "int", self.__name)),
      ("dev_velo_clusters_t", check_input_parameter(dev_velo_clusters_t, DeviceInput, "int"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_total_number_of_velo_clusters_t(self):
    return self.__ordered_parameters["host_total_number_of_velo_clusters_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_offsets_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_offsets_estimated_input_size_t"]

  def dev_module_cluster_num_t(self):
    return self.__ordered_parameters["dev_module_cluster_num_t"]

  def dev_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_velo_cluster_container_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_sorted_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_sorted_velo_cluster_container_t"]

  def dev_hit_permutation_t(self):
    return self.__ordered_parameters["dev_hit_permutation_t"]

  def dev_hit_phi_t(self):
    return self.__ordered_parameters["dev_hit_phi_t"]

  def dev_velo_clusters_t(self):
    return self.__ordered_parameters["dev_velo_clusters_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_consolidate_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_accumulated_number_of_hits_in_velo_tracks_t",
    "host_number_of_reconstructed_velo_tracks_t",
    "host_number_of_three_hit_tracks_filtered_t",
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_sorted_velo_cluster_container_t",
    "dev_offsets_estimated_input_size_t",
    "dev_three_hit_tracks_output_t",
    "dev_offsets_number_of_three_hit_tracks_filtered_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_accepted_velo_tracks_t",
    "dev_velo_track_hits_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_consolidate_tracks"

  def __init__(self,
    host_accumulated_number_of_hits_in_velo_tracks_t,
    host_number_of_reconstructed_velo_tracks_t,
    host_number_of_three_hit_tracks_filtered_t,
    host_number_of_events_t,
    dev_event_list_t,
    dev_offsets_all_velo_tracks_t,
    dev_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_sorted_velo_cluster_container_t,
    dev_offsets_estimated_input_size_t,
    dev_three_hit_tracks_output_t,
    dev_offsets_number_of_three_hit_tracks_filtered_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_consolidate_tracks_t"):
    self.__filename = "device/velo/consolidate_tracks/include/VeloConsolidateTracks.cuh"
    self.__name = name
    self.__original_name = "velo_consolidate_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_accumulated_number_of_hits_in_velo_tracks_t", check_input_parameter(host_accumulated_number_of_hits_in_velo_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_three_hit_tracks_filtered_t", check_input_parameter(host_number_of_three_hit_tracks_filtered_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_sorted_velo_cluster_container_t", check_input_parameter(dev_sorted_velo_cluster_container_t, DeviceInput, "char")),
      ("dev_offsets_estimated_input_size_t", check_input_parameter(dev_offsets_estimated_input_size_t, DeviceInput, "unsigned int")),
      ("dev_three_hit_tracks_output_t", check_input_parameter(dev_three_hit_tracks_output_t, DeviceInput, "int")),
      ("dev_offsets_number_of_three_hit_tracks_filtered_t", check_input_parameter(dev_offsets_number_of_three_hit_tracks_filtered_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_accepted_velo_tracks_t", DeviceOutput("dev_accepted_velo_tracks_t", "bool", self.__name)),
      ("dev_velo_track_hits_t", DeviceOutput("dev_velo_track_hits_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_accumulated_number_of_hits_in_velo_tracks_t(self):
    return self.__ordered_parameters["host_accumulated_number_of_hits_in_velo_tracks_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def host_number_of_three_hit_tracks_filtered_t(self):
    return self.__ordered_parameters["host_number_of_three_hit_tracks_filtered_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_sorted_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_sorted_velo_cluster_container_t"]

  def dev_offsets_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_offsets_estimated_input_size_t"]

  def dev_three_hit_tracks_output_t(self):
    return self.__ordered_parameters["dev_three_hit_tracks_output_t"]

  def dev_offsets_number_of_three_hit_tracks_filtered_t(self):
    return self.__ordered_parameters["dev_offsets_number_of_three_hit_tracks_filtered_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_accepted_velo_tracks_t(self):
    return self.__ordered_parameters["dev_accepted_velo_tracks_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_copy_track_hit_number_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_velo_tracks_at_least_four_hits_t",
    "host_number_of_three_hit_tracks_filtered_t",
    "dev_tracks_t",
    "dev_offsets_velo_tracks_t",
    "dev_offsets_number_of_three_hit_tracks_filtered_t",)
  outputs = (
    "host_number_of_reconstructed_velo_tracks_t",
    "dev_velo_track_hit_number_t",
    "dev_offsets_all_velo_tracks_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_copy_track_hit_number"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_velo_tracks_at_least_four_hits_t,
    host_number_of_three_hit_tracks_filtered_t,
    dev_tracks_t,
    dev_offsets_velo_tracks_t,
    dev_offsets_number_of_three_hit_tracks_filtered_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_copy_track_hit_number_t"):
    self.__filename = "device/velo/consolidate_tracks/include/VeloCopyTrackHitNumber.cuh"
    self.__name = name
    self.__original_name = "velo_copy_track_hit_number_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_velo_tracks_at_least_four_hits_t", check_input_parameter(host_number_of_velo_tracks_at_least_four_hits_t, HostInput, "unsigned int")),
      ("host_number_of_three_hit_tracks_filtered_t", check_input_parameter(host_number_of_three_hit_tracks_filtered_t, HostInput, "unsigned int")),
      ("host_number_of_reconstructed_velo_tracks_t", HostOutput("host_number_of_reconstructed_velo_tracks_t", "unsigned int", self.__name)),
      ("dev_tracks_t", check_input_parameter(dev_tracks_t, DeviceInput, "int")),
      ("dev_offsets_velo_tracks_t", check_input_parameter(dev_offsets_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_number_of_three_hit_tracks_filtered_t", check_input_parameter(dev_offsets_number_of_three_hit_tracks_filtered_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hit_number_t", DeviceOutput("dev_velo_track_hit_number_t", "unsigned int", self.__name)),
      ("dev_offsets_all_velo_tracks_t", DeviceOutput("dev_offsets_all_velo_tracks_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_velo_tracks_at_least_four_hits_t(self):
    return self.__ordered_parameters["host_number_of_velo_tracks_at_least_four_hits_t"]

  def host_number_of_three_hit_tracks_filtered_t(self):
    return self.__ordered_parameters["host_number_of_three_hit_tracks_filtered_t"]

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_offsets_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_velo_tracks_t"]

  def dev_offsets_number_of_three_hit_tracks_filtered_t(self):
    return self.__ordered_parameters["dev_offsets_number_of_three_hit_tracks_filtered_t"]

  def dev_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_velo_track_hit_number_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_estimate_input_size_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_cluster_candidates_t",
    "dev_event_list_t",
    "dev_candidates_offsets_t",
    "dev_velo_raw_input_t",
    "dev_velo_raw_input_offsets_t",)
  outputs = (
    "dev_estimated_input_size_t",
    "dev_module_candidate_num_t",
    "dev_cluster_candidates_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_estimate_input_size"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_cluster_candidates_t,
    dev_event_list_t,
    dev_candidates_offsets_t,
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_estimate_input_size_t"):
    self.__filename = "device/velo/mask_clustering/include/EstimateInputSize.cuh"
    self.__name = name
    self.__original_name = "velo_estimate_input_size_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_cluster_candidates_t", check_input_parameter(host_number_of_cluster_candidates_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_candidates_offsets_t", check_input_parameter(dev_candidates_offsets_t, DeviceInput, "unsigned int")),
      ("dev_velo_raw_input_t", check_input_parameter(dev_velo_raw_input_t, DeviceInput, "char")),
      ("dev_velo_raw_input_offsets_t", check_input_parameter(dev_velo_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_estimated_input_size_t", DeviceOutput("dev_estimated_input_size_t", "unsigned int", self.__name)),
      ("dev_module_candidate_num_t", DeviceOutput("dev_module_candidate_num_t", "unsigned int", self.__name)),
      ("dev_cluster_candidates_t", DeviceOutput("dev_cluster_candidates_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_cluster_candidates_t(self):
    return self.__ordered_parameters["host_number_of_cluster_candidates_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_candidates_offsets_t(self):
    return self.__ordered_parameters["dev_candidates_offsets_t"]

  def dev_velo_raw_input_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_t"]

  def dev_velo_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_offsets_t"]

  def dev_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_estimated_input_size_t"]

  def dev_module_candidate_num_t(self):
    return self.__ordered_parameters["dev_module_candidate_num_t"]

  def dev_cluster_candidates_t(self):
    return self.__ordered_parameters["dev_cluster_candidates_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_masked_clustering_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_total_number_of_velo_clusters_t",
    "host_number_of_events_t",
    "dev_velo_raw_input_t",
    "dev_velo_raw_input_offsets_t",
    "dev_offsets_estimated_input_size_t",
    "dev_module_candidate_num_t",
    "dev_cluster_candidates_t",
    "dev_event_list_t",
    "dev_candidates_offsets_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_module_cluster_num_t",
    "dev_velo_cluster_container_t",
    "dev_velo_clusters_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_masked_clustering"

  def __init__(self,
    host_total_number_of_velo_clusters_t,
    host_number_of_events_t,
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    dev_offsets_estimated_input_size_t,
    dev_module_candidate_num_t,
    dev_cluster_candidates_t,
    dev_event_list_t,
    dev_candidates_offsets_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_masked_clustering_t"):
    self.__filename = "device/velo/mask_clustering/include/MaskedVeloClustering.cuh"
    self.__name = name
    self.__original_name = "velo_masked_clustering_t"
    self.__ordered_parameters = OrderedDict([
      ("host_total_number_of_velo_clusters_t", check_input_parameter(host_total_number_of_velo_clusters_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_velo_raw_input_t", check_input_parameter(dev_velo_raw_input_t, DeviceInput, "char")),
      ("dev_velo_raw_input_offsets_t", check_input_parameter(dev_velo_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_offsets_estimated_input_size_t", check_input_parameter(dev_offsets_estimated_input_size_t, DeviceInput, "unsigned int")),
      ("dev_module_candidate_num_t", check_input_parameter(dev_module_candidate_num_t, DeviceInput, "unsigned int")),
      ("dev_cluster_candidates_t", check_input_parameter(dev_cluster_candidates_t, DeviceInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_candidates_offsets_t", check_input_parameter(dev_candidates_offsets_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_module_cluster_num_t", DeviceOutput("dev_module_cluster_num_t", "unsigned int", self.__name)),
      ("dev_velo_cluster_container_t", DeviceOutput("dev_velo_cluster_container_t", "char", self.__name)),
      ("dev_velo_clusters_t", DeviceOutput("dev_velo_clusters_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_total_number_of_velo_clusters_t(self):
    return self.__ordered_parameters["host_total_number_of_velo_clusters_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_velo_raw_input_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_t"]

  def dev_velo_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_offsets_t"]

  def dev_offsets_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_offsets_estimated_input_size_t"]

  def dev_module_candidate_num_t(self):
    return self.__ordered_parameters["dev_module_candidate_num_t"]

  def dev_cluster_candidates_t(self):
    return self.__ordered_parameters["dev_cluster_candidates_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_candidates_offsets_t(self):
    return self.__ordered_parameters["dev_candidates_offsets_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_module_cluster_num_t(self):
    return self.__ordered_parameters["dev_module_cluster_num_t"]

  def dev_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_velo_cluster_container_t"]

  def dev_velo_clusters_t(self):
    return self.__ordered_parameters["dev_velo_clusters_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_calculate_number_of_candidates_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_velo_raw_input_t",
    "dev_velo_raw_input_offsets_t",)
  outputs = (
    "dev_number_of_candidates_t",)
  props = (
    "verbosity",
    "block_dim_x",)
  aggregates = ()
  namespace = "velo_calculate_number_of_candidates"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_velo_raw_input_t,
    dev_velo_raw_input_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension X"),
    name="velo_calculate_number_of_candidates_t"):
    self.__filename = "device/velo/mask_clustering/include/VeloCalculateNumberOfCandidates.cuh"
    self.__name = name
    self.__original_name = "velo_calculate_number_of_candidates_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_raw_input_t", check_input_parameter(dev_velo_raw_input_t, DeviceInput, "char")),
      ("dev_velo_raw_input_offsets_t", check_input_parameter(dev_velo_raw_input_offsets_t, DeviceInput, "unsigned int")),
      ("dev_number_of_candidates_t", DeviceOutput("dev_number_of_candidates_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension X", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_raw_input_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_t"]

  def dev_velo_raw_input_offsets_t(self):
    return self.__ordered_parameters["dev_velo_raw_input_offsets_t"]

  def dev_number_of_candidates_t(self):
    return self.__ordered_parameters["dev_number_of_candidates_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_search_by_triplet_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_total_number_of_velo_clusters_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_sorted_velo_cluster_container_t",
    "dev_offsets_estimated_input_size_t",
    "dev_module_cluster_num_t",
    "dev_hit_phi_t",
    "dev_velo_clusters_t",)
  outputs = (
    "dev_tracks_t",
    "dev_tracklets_t",
    "dev_tracks_to_follow_t",
    "dev_three_hit_tracks_t",
    "dev_hit_used_t",
    "dev_atomics_velo_t",
    "dev_rel_indices_t",
    "dev_number_of_velo_tracks_t",)
  props = (
    "verbosity",
    "phi_tolerance",
    "max_scatter",
    "max_skipped_modules",
    "block_dim_x",)
  aggregates = ()
  namespace = "velo_search_by_triplet"

  def __init__(self,
    host_number_of_events_t,
    host_total_number_of_velo_clusters_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_sorted_velo_cluster_container_t,
    dev_offsets_estimated_input_size_t,
    dev_module_cluster_num_t,
    dev_hit_phi_t,
    dev_velo_clusters_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    phi_tolerance=Property("float", "", "tolerance in phi"),
    max_scatter=Property("float", "", "maximum scatter for seeding and forwarding"),
    max_skipped_modules=Property("unsigned int", "", "skipped modules"),
    block_dim_x=Property("unsigned int", "", "block dimension x"),
    name="velo_search_by_triplet_t"):
    self.__filename = "device/velo/search_by_triplet/include/SearchByTriplet.cuh"
    self.__name = name
    self.__original_name = "velo_search_by_triplet_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_total_number_of_velo_clusters_t", check_input_parameter(host_total_number_of_velo_clusters_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_sorted_velo_cluster_container_t", check_input_parameter(dev_sorted_velo_cluster_container_t, DeviceInput, "char")),
      ("dev_offsets_estimated_input_size_t", check_input_parameter(dev_offsets_estimated_input_size_t, DeviceInput, "unsigned int")),
      ("dev_module_cluster_num_t", check_input_parameter(dev_module_cluster_num_t, DeviceInput, "unsigned int")),
      ("dev_hit_phi_t", check_input_parameter(dev_hit_phi_t, DeviceInput, "int")),
      ("dev_tracks_t", DeviceOutput("dev_tracks_t", "int", self.__name)),
      ("dev_tracklets_t", DeviceOutput("dev_tracklets_t", "int", self.__name)),
      ("dev_tracks_to_follow_t", DeviceOutput("dev_tracks_to_follow_t", "unsigned int", self.__name)),
      ("dev_three_hit_tracks_t", DeviceOutput("dev_three_hit_tracks_t", "int", self.__name)),
      ("dev_hit_used_t", DeviceOutput("dev_hit_used_t", "bool", self.__name)),
      ("dev_atomics_velo_t", DeviceOutput("dev_atomics_velo_t", "unsigned int", self.__name)),
      ("dev_rel_indices_t", DeviceOutput("dev_rel_indices_t", "unsigned short", self.__name)),
      ("dev_number_of_velo_tracks_t", DeviceOutput("dev_number_of_velo_tracks_t", "unsigned int", self.__name)),
      ("dev_velo_clusters_t", check_input_parameter(dev_velo_clusters_t, DeviceInput, "int"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("phi_tolerance", Property("float", "", "tolerance in phi", phi_tolerance)),
      ("max_scatter", Property("float", "", "maximum scatter for seeding and forwarding", max_scatter)),
      ("max_skipped_modules", Property("unsigned int", "", "skipped modules", max_skipped_modules)),
      ("block_dim_x", Property("unsigned int", "", "block dimension x", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_total_number_of_velo_clusters_t(self):
    return self.__ordered_parameters["host_total_number_of_velo_clusters_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_sorted_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_sorted_velo_cluster_container_t"]

  def dev_offsets_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_offsets_estimated_input_size_t"]

  def dev_module_cluster_num_t(self):
    return self.__ordered_parameters["dev_module_cluster_num_t"]

  def dev_hit_phi_t(self):
    return self.__ordered_parameters["dev_hit_phi_t"]

  def dev_tracks_t(self):
    return self.__ordered_parameters["dev_tracks_t"]

  def dev_tracklets_t(self):
    return self.__ordered_parameters["dev_tracklets_t"]

  def dev_tracks_to_follow_t(self):
    return self.__ordered_parameters["dev_tracks_to_follow_t"]

  def dev_three_hit_tracks_t(self):
    return self.__ordered_parameters["dev_three_hit_tracks_t"]

  def dev_hit_used_t(self):
    return self.__ordered_parameters["dev_hit_used_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_rel_indices_t(self):
    return self.__ordered_parameters["dev_rel_indices_t"]

  def dev_number_of_velo_tracks_t(self):
    return self.__ordered_parameters["dev_number_of_velo_tracks_t"]

  def dev_velo_clusters_t(self):
    return self.__ordered_parameters["dev_velo_clusters_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def phi_tolerance(self):
    return self.__ordered_properties["phi_tolerance"]

  def max_scatter(self):
    return self.__ordered_properties["max_scatter"]

  def max_skipped_modules(self):
    return self.__ordered_properties["max_skipped_modules"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_three_hit_tracks_filter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_sorted_velo_cluster_container_t",
    "dev_offsets_estimated_input_size_t",
    "dev_three_hit_tracks_input_t",
    "dev_atomics_velo_t",
    "dev_hit_used_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_three_hit_tracks_output_t",
    "dev_number_of_three_hit_tracks_output_t",)
  props = (
    "verbosity",
    "max_chi2",
    "max_weak_tracks",
    "block_dim",)
  aggregates = ()
  namespace = "velo_three_hit_tracks_filter"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_sorted_velo_cluster_container_t,
    dev_offsets_estimated_input_size_t,
    dev_three_hit_tracks_input_t,
    dev_atomics_velo_t,
    dev_hit_used_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    max_chi2=Property("float", "", "chi2"),
    max_weak_tracks=Property("unsigned int", "", "max weak tracks"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_three_hit_tracks_filter_t"):
    self.__filename = "device/velo/search_by_triplet/include/ThreeHitTracksFilter.cuh"
    self.__name = name
    self.__original_name = "velo_three_hit_tracks_filter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_sorted_velo_cluster_container_t", check_input_parameter(dev_sorted_velo_cluster_container_t, DeviceInput, "char")),
      ("dev_offsets_estimated_input_size_t", check_input_parameter(dev_offsets_estimated_input_size_t, DeviceInput, "unsigned int")),
      ("dev_three_hit_tracks_input_t", check_input_parameter(dev_three_hit_tracks_input_t, DeviceInput, "int")),
      ("dev_atomics_velo_t", check_input_parameter(dev_atomics_velo_t, DeviceInput, "unsigned int")),
      ("dev_hit_used_t", check_input_parameter(dev_hit_used_t, DeviceInput, "bool")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_three_hit_tracks_output_t", DeviceOutput("dev_three_hit_tracks_output_t", "int", self.__name)),
      ("dev_number_of_three_hit_tracks_output_t", DeviceOutput("dev_number_of_three_hit_tracks_output_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("max_chi2", Property("float", "", "chi2", max_chi2)),
      ("max_weak_tracks", Property("unsigned int", "", "max weak tracks", max_weak_tracks)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_sorted_velo_cluster_container_t(self):
    return self.__ordered_parameters["dev_sorted_velo_cluster_container_t"]

  def dev_offsets_estimated_input_size_t(self):
    return self.__ordered_parameters["dev_offsets_estimated_input_size_t"]

  def dev_three_hit_tracks_input_t(self):
    return self.__ordered_parameters["dev_three_hit_tracks_input_t"]

  def dev_atomics_velo_t(self):
    return self.__ordered_parameters["dev_atomics_velo_t"]

  def dev_hit_used_t(self):
    return self.__ordered_parameters["dev_hit_used_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_three_hit_tracks_output_t(self):
    return self.__ordered_parameters["dev_three_hit_tracks_output_t"]

  def dev_number_of_three_hit_tracks_output_t(self):
    return self.__ordered_parameters["dev_number_of_three_hit_tracks_output_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def max_chi2(self):
    return self.__ordered_properties["max_chi2"]

  def max_weak_tracks(self):
    return self.__ordered_properties["max_weak_tracks"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class velo_kalman_filter_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_reconstructed_velo_tracks_t",
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",)
  outputs = (
    "dev_velo_kalman_beamline_states_t",
    "dev_velo_kalman_endvelo_states_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "velo_kalman_filter"

  def __init__(self,
    host_number_of_reconstructed_velo_tracks_t,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="velo_kalman_filter_t"):
    self.__filename = "device/velo/simplified_kalman_filter/include/VeloKalmanFilter.cuh"
    self.__name = name
    self.__original_name = "velo_kalman_filter_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_reconstructed_velo_tracks_t", check_input_parameter(host_number_of_reconstructed_velo_tracks_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_velo_kalman_beamline_states_t", DeviceOutput("dev_velo_kalman_beamline_states_t", "char", self.__name)),
      ("dev_velo_kalman_endvelo_states_t", DeviceOutput("dev_velo_kalman_endvelo_states_t", "char", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_reconstructed_velo_tracks_t(self):
    return self.__ordered_parameters["host_number_of_reconstructed_velo_tracks_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_velo_kalman_beamline_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_beamline_states_t"]

  def dev_velo_kalman_endvelo_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_endvelo_states_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class consolidate_svs_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_svs_t",
    "host_number_of_events_t",
    "dev_sv_offsets_t",
    "dev_secondary_vertices_t",)
  outputs = (
    "dev_consolidated_svs_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "consolidate_svs"

  def __init__(self,
    host_number_of_svs_t,
    host_number_of_events_t,
    dev_sv_offsets_t,
    dev_secondary_vertices_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="consolidate_svs_t"):
    self.__filename = "device/vertex_fit/vertex_fitter/include/ConsolidateSVs.cuh"
    self.__name = name
    self.__original_name = "consolidate_svs_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_secondary_vertices_t", check_input_parameter(dev_secondary_vertices_t, DeviceInput, "int")),
      ("dev_consolidated_svs_t", DeviceOutput("dev_consolidated_svs_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_secondary_vertices_t(self):
    return self.__ordered_parameters["dev_secondary_vertices_t"]

  def dev_consolidated_svs_t(self):
    return self.__ordered_parameters["dev_consolidated_svs_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class filter_mf_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_selected_events_mf_t",
    "dev_kf_tracks_t",
    "dev_mf_tracks_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_mf_track_offsets_t",
    "dev_event_list_mf_t",)
  outputs = (
    "dev_mf_sv_atomics_t",
    "dev_svs_kf_idx_t",
    "dev_svs_mf_idx_t",)
  props = (
    "verbosity",
    "kf_track_min_pt",
    "kf_track_min_ipchi2",
    "mf_track_min_pt",
    "block_dim",)
  aggregates = ()
  namespace = "FilterMFTracks"

  def __init__(self,
    host_number_of_events_t,
    host_selected_events_mf_t,
    dev_kf_tracks_t,
    dev_mf_tracks_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_mf_track_offsets_t,
    dev_event_list_mf_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    kf_track_min_pt=Property("float", "", "minimum track pT"),
    kf_track_min_ipchi2=Property("float", "", "minimum track IP chi2"),
    mf_track_min_pt=Property("float", "", "minimum velo-UT-muon track pt"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="filter_mf_tracks_t"):
    self.__filename = "device/vertex_fit/vertex_fitter/include/FilterMFTracks.cuh"
    self.__name = name
    self.__original_name = "filter_mf_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_selected_events_mf_t", check_input_parameter(host_selected_events_mf_t, HostInput, "unsigned int")),
      ("dev_kf_tracks_t", check_input_parameter(dev_kf_tracks_t, DeviceInput, "int")),
      ("dev_mf_tracks_t", check_input_parameter(dev_mf_tracks_t, DeviceInput, "int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number", check_input_parameter(dev_offsets_scifi_track_hit_number, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_mf_track_offsets_t", check_input_parameter(dev_mf_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_event_list_mf_t", check_input_parameter(dev_event_list_mf_t, DeviceInput, "unsigned int")),
      ("dev_mf_sv_atomics_t", DeviceOutput("dev_mf_sv_atomics_t", "unsigned int", self.__name)),
      ("dev_svs_kf_idx_t", DeviceOutput("dev_svs_kf_idx_t", "unsigned int", self.__name)),
      ("dev_svs_mf_idx_t", DeviceOutput("dev_svs_mf_idx_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("kf_track_min_pt", Property("float", "", "minimum track pT", kf_track_min_pt)),
      ("kf_track_min_ipchi2", Property("float", "", "minimum track IP chi2", kf_track_min_ipchi2)),
      ("mf_track_min_pt", Property("float", "", "minimum velo-UT-muon track pt", mf_track_min_pt)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_selected_events_mf_t(self):
    return self.__ordered_parameters["host_selected_events_mf_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_mf_tracks_t(self):
    return self.__ordered_parameters["dev_mf_tracks_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_mf_track_offsets_t(self):
    return self.__ordered_parameters["dev_mf_track_offsets_t"]

  def dev_event_list_mf_t(self):
    return self.__ordered_parameters["dev_event_list_mf_t"]

  def dev_mf_sv_atomics_t(self):
    return self.__ordered_parameters["dev_mf_sv_atomics_t"]

  def dev_svs_kf_idx_t(self):
    return self.__ordered_parameters["dev_svs_kf_idx_t"]

  def dev_svs_mf_idx_t(self):
    return self.__ordered_parameters["dev_svs_mf_idx_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def kf_track_min_pt(self):
    return self.__ordered_properties["kf_track_min_pt"]

  def kf_track_min_ipchi2(self):
    return self.__ordered_properties["kf_track_min_ipchi2"]

  def mf_track_min_pt(self):
    return self.__ordered_properties["mf_track_min_pt"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class filter_tracks_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_kf_tracks_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",
    "dev_kalman_pv_ipchi2_t",)
  outputs = (
    "dev_sv_atomics_t",
    "dev_svs_trk1_idx_t",
    "dev_svs_trk2_idx_t",)
  props = (
    "verbosity",
    "track_min_pt",
    "track_min_ipchi2",
    "track_muon_min_ipchi2",
    "track_max_chi2ndof",
    "track_muon_max_chi2ndof",
    "max_assoc_ipchi2",
    "block_dim",)
  aggregates = ()
  namespace = "FilterTracks"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_kf_tracks_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    dev_kalman_pv_ipchi2_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    track_min_pt=Property("float", "", "minimum track pT"),
    track_min_ipchi2=Property("float", "", "minimum track IP chi2"),
    track_muon_min_ipchi2=Property("float", "", "minimum muon IP chi2"),
    track_max_chi2ndof=Property("float", "", "max track chi2/ndof"),
    track_muon_max_chi2ndof=Property("float", "", "max muon chi2/ndof"),
    max_assoc_ipchi2=Property("float", "", "maximum IP chi2 to associate to PV"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="filter_tracks_t"):
    self.__filename = "device/vertex_fit/vertex_fitter/include/FilterTracks.cuh"
    self.__name = name
    self.__original_name = "filter_tracks_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_kf_tracks_t", check_input_parameter(dev_kf_tracks_t, DeviceInput, "int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("dev_kalman_pv_ipchi2_t", check_input_parameter(dev_kalman_pv_ipchi2_t, DeviceInput, "char")),
      ("dev_sv_atomics_t", DeviceOutput("dev_sv_atomics_t", "unsigned int", self.__name)),
      ("dev_svs_trk1_idx_t", DeviceOutput("dev_svs_trk1_idx_t", "unsigned int", self.__name)),
      ("dev_svs_trk2_idx_t", DeviceOutput("dev_svs_trk2_idx_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("track_min_pt", Property("float", "", "minimum track pT", track_min_pt)),
      ("track_min_ipchi2", Property("float", "", "minimum track IP chi2", track_min_ipchi2)),
      ("track_muon_min_ipchi2", Property("float", "", "minimum muon IP chi2", track_muon_min_ipchi2)),
      ("track_max_chi2ndof", Property("float", "", "max track chi2/ndof", track_max_chi2ndof)),
      ("track_muon_max_chi2ndof", Property("float", "", "max muon chi2/ndof", track_muon_max_chi2ndof)),
      ("max_assoc_ipchi2", Property("float", "", "maximum IP chi2 to associate to PV", max_assoc_ipchi2)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def dev_kalman_pv_ipchi2_t(self):
    return self.__ordered_parameters["dev_kalman_pv_ipchi2_t"]

  def dev_sv_atomics_t(self):
    return self.__ordered_parameters["dev_sv_atomics_t"]

  def dev_svs_trk1_idx_t(self):
    return self.__ordered_parameters["dev_svs_trk1_idx_t"]

  def dev_svs_trk2_idx_t(self):
    return self.__ordered_parameters["dev_svs_trk2_idx_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def track_min_pt(self):
    return self.__ordered_properties["track_min_pt"]

  def track_min_ipchi2(self):
    return self.__ordered_properties["track_min_ipchi2"]

  def track_muon_min_ipchi2(self):
    return self.__ordered_properties["track_muon_min_ipchi2"]

  def track_max_chi2ndof(self):
    return self.__ordered_properties["track_max_chi2ndof"]

  def track_muon_max_chi2ndof(self):
    return self.__ordered_properties["track_muon_max_chi2ndof"]

  def max_assoc_ipchi2(self):
    return self.__ordered_properties["max_assoc_ipchi2"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class fit_mf_vertices_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_mf_svs_t",
    "host_selected_events_mf_t",
    "dev_kf_tracks_t",
    "dev_mf_tracks_t",
    "dev_offsets_forward_tracks_t",
    "dev_mf_track_offsets_t",
    "dev_mf_sv_offsets_t",
    "dev_svs_kf_idx_t",
    "dev_svs_mf_idx_t",
    "dev_event_list_mf_t",)
  outputs = (
    "dev_mf_svs_t",)
  props = (
    "verbosity",
    "block_dim",)
  aggregates = ()
  namespace = "MFVertexFit"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_mf_svs_t,
    host_selected_events_mf_t,
    dev_kf_tracks_t,
    dev_mf_tracks_t,
    dev_offsets_forward_tracks_t,
    dev_mf_track_offsets_t,
    dev_mf_sv_offsets_t,
    dev_svs_kf_idx_t,
    dev_svs_mf_idx_t,
    dev_event_list_mf_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="fit_mf_vertices_t"):
    self.__filename = "device/vertex_fit/vertex_fitter/include/MFVertexFitter.cuh"
    self.__name = name
    self.__original_name = "fit_mf_vertices_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_mf_svs_t", check_input_parameter(host_number_of_mf_svs_t, HostInput, "unsigned int")),
      ("host_selected_events_mf_t", check_input_parameter(host_selected_events_mf_t, HostInput, "unsigned int")),
      ("dev_kf_tracks_t", check_input_parameter(dev_kf_tracks_t, DeviceInput, "int")),
      ("dev_mf_tracks_t", check_input_parameter(dev_mf_tracks_t, DeviceInput, "int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_mf_track_offsets_t", check_input_parameter(dev_mf_track_offsets_t, DeviceInput, "unsigned int")),
      ("dev_mf_sv_offsets_t", check_input_parameter(dev_mf_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_svs_kf_idx_t", check_input_parameter(dev_svs_kf_idx_t, DeviceInput, "unsigned int")),
      ("dev_svs_mf_idx_t", check_input_parameter(dev_svs_mf_idx_t, DeviceInput, "unsigned int")),
      ("dev_event_list_mf_t", check_input_parameter(dev_event_list_mf_t, DeviceInput, "unsigned int")),
      ("dev_mf_svs_t", DeviceOutput("dev_mf_svs_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_mf_svs_t(self):
    return self.__ordered_parameters["host_number_of_mf_svs_t"]

  def host_selected_events_mf_t(self):
    return self.__ordered_parameters["host_selected_events_mf_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_mf_tracks_t(self):
    return self.__ordered_parameters["dev_mf_tracks_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_mf_track_offsets_t(self):
    return self.__ordered_parameters["dev_mf_track_offsets_t"]

  def dev_mf_sv_offsets_t(self):
    return self.__ordered_parameters["dev_mf_sv_offsets_t"]

  def dev_svs_kf_idx_t(self):
    return self.__ordered_parameters["dev_svs_kf_idx_t"]

  def dev_svs_mf_idx_t(self):
    return self.__ordered_parameters["dev_svs_mf_idx_t"]

  def dev_event_list_mf_t(self):
    return self.__ordered_parameters["dev_event_list_mf_t"]

  def dev_mf_svs_t(self):
    return self.__ordered_parameters["dev_mf_svs_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class fit_secondary_vertices_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_number_of_svs_t",
    "dev_event_list_t",
    "dev_number_of_events_t",
    "dev_kf_tracks_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_scifi_track_ut_indices_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",
    "dev_kalman_pv_ipchi2_t",
    "dev_svs_trk1_idx_t",
    "dev_svs_trk2_idx_t",
    "dev_sv_offsets_t",)
  outputs = (
    "dev_consolidated_svs_t",)
  props = (
    "verbosity",
    "max_assoc_ipchi2",
    "block_dim",)
  aggregates = ()
  namespace = "VertexFit"

  def __init__(self,
    host_number_of_events_t,
    host_number_of_svs_t,
    dev_event_list_t,
    dev_number_of_events_t,
    dev_kf_tracks_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_scifi_track_ut_indices_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    dev_kalman_pv_ipchi2_t,
    dev_svs_trk1_idx_t,
    dev_svs_trk2_idx_t,
    dev_sv_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    max_assoc_ipchi2=Property("float", "", "maximum IP chi2 to associate to PV"),
    block_dim=Property("DeviceDimensions", "", "block dimensions"),
    name="fit_secondary_vertices_t"):
    self.__filename = "device/vertex_fit/vertex_fitter/include/VertexFitter.cuh"
    self.__name = name
    self.__original_name = "fit_secondary_vertices_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_number_of_svs_t", check_input_parameter(host_number_of_svs_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_kf_tracks_t", check_input_parameter(dev_kf_tracks_t, DeviceInput, "int")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("dev_kalman_pv_ipchi2_t", check_input_parameter(dev_kalman_pv_ipchi2_t, DeviceInput, "char")),
      ("dev_svs_trk1_idx_t", check_input_parameter(dev_svs_trk1_idx_t, DeviceInput, "unsigned int")),
      ("dev_svs_trk2_idx_t", check_input_parameter(dev_svs_trk2_idx_t, DeviceInput, "unsigned int")),
      ("dev_sv_offsets_t", check_input_parameter(dev_sv_offsets_t, DeviceInput, "unsigned int")),
      ("dev_consolidated_svs_t", DeviceOutput("dev_consolidated_svs_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("max_assoc_ipchi2", Property("float", "", "maximum IP chi2 to associate to PV", max_assoc_ipchi2)),
      ("block_dim", Property("DeviceDimensions", "", "block dimensions", block_dim))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_svs_t(self):
    return self.__ordered_parameters["host_number_of_svs_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def dev_kalman_pv_ipchi2_t(self):
    return self.__ordered_parameters["dev_kalman_pv_ipchi2_t"]

  def dev_svs_trk1_idx_t(self):
    return self.__ordered_parameters["dev_svs_trk1_idx_t"]

  def dev_svs_trk2_idx_t(self):
    return self.__ordered_parameters["dev_svs_trk2_idx_t"]

  def dev_sv_offsets_t(self):
    return self.__ordered_parameters["dev_sv_offsets_t"]

  def dev_consolidated_svs_t(self):
    return self.__ordered_parameters["dev_consolidated_svs_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def max_assoc_ipchi2(self):
    return self.__ordered_properties["max_assoc_ipchi2"]

  def block_dim(self):
    return self.__ordered_properties["block_dim"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class calo_count_digits_t(DeviceAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_event_list_t",
    "dev_number_of_events_t",)
  outputs = (
    "dev_ecal_num_digits_t",
    "dev_hcal_num_digits_t",)
  props = (
    "verbosity",
    "block_dim_x",)
  aggregates = ()
  namespace = "calo_count_digits"

  def __init__(self,
    host_number_of_events_t,
    dev_event_list_t,
    dev_number_of_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    block_dim_x=Property("unsigned int", "", "block dimension X"),
    name="calo_count_digits_t"):
    self.__filename = "device/calo/decoding/include/CaloCountDigits.cuh"
    self.__name = name
    self.__original_name = "calo_count_digits_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_number_of_events_t", check_input_parameter(dev_number_of_events_t, DeviceInput, "unsigned int")),
      ("dev_ecal_num_digits_t", DeviceOutput("dev_ecal_num_digits_t", "unsigned int", self.__name)),
      ("dev_hcal_num_digits_t", DeviceOutput("dev_hcal_num_digits_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("block_dim_x", Property("unsigned int", "", "block dimension X", block_dim_x))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_ecal_num_digits_t(self):
    return self.__ordered_parameters["dev_ecal_num_digits_t"]

  def dev_hcal_num_digits_t(self):
    return self.__ordered_parameters["dev_hcal_num_digits_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def block_dim_x(self):
    return self.__ordered_properties["block_dim_x"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class data_provider_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = ()
  outputs = (
    "dev_raw_banks_t",
    "dev_raw_offsets_t",)
  props = (
    "verbosity",
    "bank_type",)
  aggregates = ()
  namespace = "data_provider"

  def __init__(self,
    verbosity=Property("int", "", "verbosity of algorithm"),
    bank_type=Property("int", "", "type of raw bank to provide"),
    name="data_provider_t"):
    self.__filename = "host/data_provider/include/DataProvider.h"
    self.__name = name
    self.__original_name = "data_provider_t"
    self.__ordered_parameters = OrderedDict([
      ("dev_raw_banks_t", DeviceOutput("dev_raw_banks_t", "char", self.__name)),
      ("dev_raw_offsets_t", DeviceOutput("dev_raw_offsets_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("bank_type", Property("int", "", "type of raw bank to provide", bank_type))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def dev_raw_banks_t(self):
    return self.__ordered_parameters["dev_raw_banks_t"]

  def dev_raw_offsets_t(self):
    return self.__ordered_parameters["dev_raw_offsets_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def bank_type(self):
    return self.__ordered_properties["bank_type"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_data_provider_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = ()
  outputs = (
    "host_raw_banks_t",
    "host_raw_offsets_t",)
  props = (
    "verbosity",
    "bank_type",)
  aggregates = ()
  namespace = "host_data_provider"

  def __init__(self,
    verbosity=Property("int", "", "verbosity of algorithm"),
    bank_type=Property("int", "", "type of raw bank to provide"),
    name="host_data_provider_t"):
    self.__filename = "host/data_provider/include/HostDataProvider.h"
    self.__name = name
    self.__original_name = "host_data_provider_t"
    self.__ordered_parameters = OrderedDict([
      ("host_raw_banks_t", HostOutput("host_raw_banks_t", "int", self.__name)),
      ("host_raw_offsets_t", HostOutput("host_raw_offsets_t", "int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("bank_type", Property("int", "", "type of raw bank to provide", bank_type))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_raw_banks_t(self):
    return self.__ordered_parameters["host_raw_banks_t"]

  def host_raw_offsets_t(self):
    return self.__ordered_parameters["host_raw_offsets_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def bank_type(self):
    return self.__ordered_properties["bank_type"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class layout_provider_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = ()
  outputs = (
    "host_mep_layout_t",
    "dev_mep_layout_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "layout_provider"

  def __init__(self,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="layout_provider_t"):
    self.__filename = "host/data_provider/include/LayoutProvider.h"
    self.__name = name
    self.__original_name = "layout_provider_t"
    self.__ordered_parameters = OrderedDict([
      ("host_mep_layout_t", HostOutput("host_mep_layout_t", "unsigned int", self.__name)),
      ("dev_mep_layout_t", DeviceOutput("dev_mep_layout_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_mep_layout_t(self):
    return self.__ordered_parameters["host_mep_layout_t"]

  def dev_mep_layout_t(self):
    return self.__ordered_parameters["dev_mep_layout_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class mc_data_provider_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = ()
  outputs = (
    "host_mc_events_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "mc_data_provider"

  def __init__(self,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="mc_data_provider_t"):
    self.__filename = "host/data_provider/include/MCDataProvider.h"
    self.__name = name
    self.__original_name = "mc_data_provider_t"
    self.__ordered_parameters = OrderedDict([
      ("host_mc_events_t", HostOutput("host_mc_events_t", "const int *", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_global_event_cut_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_ut_raw_banks_t",
    "host_ut_raw_offsets_t",
    "host_scifi_raw_banks_t",
    "host_scifi_raw_offsets_t",)
  outputs = (
    "host_event_list_t",
    "host_number_of_events_t",
    "host_number_of_selected_events_t",
    "dev_number_of_events_t",
    "dev_event_list_t",)
  props = (
    "verbosity",
    "min_scifi_ut_clusters",
    "max_scifi_ut_clusters",)
  aggregates = ()
  namespace = "host_global_event_cut"

  def __init__(self,
    host_ut_raw_banks_t,
    host_ut_raw_offsets_t,
    host_scifi_raw_banks_t,
    host_scifi_raw_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    min_scifi_ut_clusters=Property("unsigned int", "", "minimum number of scifi + ut clusters"),
    max_scifi_ut_clusters=Property("unsigned int", "", "maximum number of scifi + ut clusters"),
    name="host_global_event_cut_t"):
    self.__filename = "host/global_event_cut/include/HostGlobalEventCut.h"
    self.__name = name
    self.__original_name = "host_global_event_cut_t"
    self.__ordered_parameters = OrderedDict([
      ("host_ut_raw_banks_t", check_input_parameter(host_ut_raw_banks_t, HostInput, "int")),
      ("host_ut_raw_offsets_t", check_input_parameter(host_ut_raw_offsets_t, HostInput, "int")),
      ("host_scifi_raw_banks_t", check_input_parameter(host_scifi_raw_banks_t, HostInput, "int")),
      ("host_scifi_raw_offsets_t", check_input_parameter(host_scifi_raw_offsets_t, HostInput, "int")),
      ("host_event_list_t", HostOutput("host_event_list_t", "unsigned int", self.__name)),
      ("host_number_of_events_t", HostOutput("host_number_of_events_t", "unsigned int", self.__name)),
      ("host_number_of_selected_events_t", HostOutput("host_number_of_selected_events_t", "unsigned int", self.__name)),
      ("dev_number_of_events_t", DeviceOutput("dev_number_of_events_t", "unsigned int", self.__name)),
      ("dev_event_list_t", DeviceOutput("dev_event_list_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("min_scifi_ut_clusters", Property("unsigned int", "", "minimum number of scifi + ut clusters", min_scifi_ut_clusters)),
      ("max_scifi_ut_clusters", Property("unsigned int", "", "maximum number of scifi + ut clusters", max_scifi_ut_clusters))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_ut_raw_banks_t(self):
    return self.__ordered_parameters["host_ut_raw_banks_t"]

  def host_ut_raw_offsets_t(self):
    return self.__ordered_parameters["host_ut_raw_offsets_t"]

  def host_scifi_raw_banks_t(self):
    return self.__ordered_parameters["host_scifi_raw_banks_t"]

  def host_scifi_raw_offsets_t(self):
    return self.__ordered_parameters["host_scifi_raw_offsets_t"]

  def host_event_list_t(self):
    return self.__ordered_parameters["host_event_list_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_number_of_selected_events_t(self):
    return self.__ordered_parameters["host_number_of_selected_events_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def min_scifi_ut_clusters(self):
    return self.__ordered_properties["min_scifi_ut_clusters"]

  def max_scifi_ut_clusters(self):
    return self.__ordered_properties["max_scifi_ut_clusters"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_init_event_list_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_ut_raw_banks_t",
    "host_ut_raw_offsets_t",
    "host_scifi_raw_banks_t",
    "host_scifi_raw_offsets_t",)
  outputs = (
    "host_number_of_events_t",
    "host_event_list_t",
    "dev_number_of_events_t",
    "dev_event_list_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "host_init_event_list"

  def __init__(self,
    host_ut_raw_banks_t,
    host_ut_raw_offsets_t,
    host_scifi_raw_banks_t,
    host_scifi_raw_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="host_init_event_list_t"):
    self.__filename = "host/init_event_list/include/HostInitEventList.h"
    self.__name = name
    self.__original_name = "host_init_event_list_t"
    self.__ordered_parameters = OrderedDict([
      ("host_ut_raw_banks_t", check_input_parameter(host_ut_raw_banks_t, HostInput, "int")),
      ("host_ut_raw_offsets_t", check_input_parameter(host_ut_raw_offsets_t, HostInput, "int")),
      ("host_scifi_raw_banks_t", check_input_parameter(host_scifi_raw_banks_t, HostInput, "int")),
      ("host_scifi_raw_offsets_t", check_input_parameter(host_scifi_raw_offsets_t, HostInput, "int")),
      ("host_number_of_events_t", HostOutput("host_number_of_events_t", "unsigned int", self.__name)),
      ("host_event_list_t", HostOutput("host_event_list_t", "unsigned int", self.__name)),
      ("dev_number_of_events_t", DeviceOutput("dev_number_of_events_t", "unsigned int", self.__name)),
      ("dev_event_list_t", DeviceOutput("dev_event_list_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_ut_raw_banks_t(self):
    return self.__ordered_parameters["host_ut_raw_banks_t"]

  def host_ut_raw_offsets_t(self):
    return self.__ordered_parameters["host_ut_raw_offsets_t"]

  def host_scifi_raw_banks_t(self):
    return self.__ordered_parameters["host_scifi_raw_banks_t"]

  def host_scifi_raw_offsets_t(self):
    return self.__ordered_parameters["host_scifi_raw_offsets_t"]

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_event_list_t(self):
    return self.__ordered_parameters["host_event_list_t"]

  def dev_number_of_events_t(self):
    return self.__ordered_parameters["dev_number_of_events_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_prefix_sum_t(HostAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "dev_input_buffer_t",)
  outputs = (
    "host_total_sum_holder_t",
    "host_output_buffer_t",
    "dev_output_buffer_t",)
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "host_prefix_sum"

  def __init__(self,
    dev_input_buffer_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="host_prefix_sum_t"):
    self.__filename = "host/prefix_sum/include/HostPrefixSum.h"
    self.__name = name
    self.__original_name = "host_prefix_sum_t"
    self.__ordered_parameters = OrderedDict([
      ("host_total_sum_holder_t", HostOutput("host_total_sum_holder_t", "unsigned int", self.__name)),
      ("dev_input_buffer_t", check_input_parameter(dev_input_buffer_t, DeviceInput, "unsigned int")),
      ("host_output_buffer_t", HostOutput("host_output_buffer_t", "unsigned int", self.__name)),
      ("dev_output_buffer_t", DeviceOutput("dev_output_buffer_t", "unsigned int", self.__name))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_total_sum_holder_t(self):
    return self.__ordered_parameters["host_total_sum_holder_t"]

  def dev_input_buffer_t(self):
    return self.__ordered_parameters["dev_input_buffer_t"]

  def host_output_buffer_t(self):
    return self.__ordered_parameters["host_output_buffer_t"]

  def dev_output_buffer_t(self):
    return self.__ordered_parameters["dev_output_buffer_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_forward_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_event_list_t",
    "dev_velo_kalman_endvelo_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_track_hits_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_track_hits_t",
    "dev_scifi_track_ut_indices_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_forward_validator"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_event_list_t,
    dev_velo_kalman_endvelo_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_track_hits_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_track_hits_t,
    dev_scifi_track_ut_indices_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_forward_validator_t"):
    self.__filename = "host/validators/include/HostForwardValidator.h"
    self.__name = name
    self.__original_name = "host_forward_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_endvelo_states_t", check_input_parameter(dev_velo_kalman_endvelo_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", check_input_parameter(dev_ut_track_hits_t, DeviceInput, "char")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hits_t", check_input_parameter(dev_scifi_track_hits_t, DeviceInput, "char")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_kalman_endvelo_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_endvelo_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_track_hits_t(self):
    return self.__ordered_parameters["dev_scifi_track_hits_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_kalman_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_event_list_t",
    "dev_velo_kalman_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_track_hits_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_track_hits_t",
    "dev_scifi_track_ut_indices_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_kf_tracks_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_kalman_validator"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_event_list_t,
    dev_velo_kalman_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_track_hits_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_track_hits_t,
    dev_scifi_track_ut_indices_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_kf_tracks_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_kalman_validator_t"):
    self.__filename = "host/validators/include/HostKalmanValidator.h"
    self.__name = name
    self.__original_name = "host_kalman_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_states_t", check_input_parameter(dev_velo_kalman_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", check_input_parameter(dev_ut_track_hits_t, DeviceInput, "char")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hits_t", check_input_parameter(dev_scifi_track_hits_t, DeviceInput, "char")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_kf_tracks_t", check_input_parameter(dev_kf_tracks_t, DeviceInput, "int")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_kalman_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_track_hits_t(self):
    return self.__ordered_parameters["dev_scifi_track_hits_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_kf_tracks_t(self):
    return self.__ordered_parameters["dev_kf_tracks_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_muon_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_event_list_t",
    "dev_velo_kalman_endvelo_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_track_hits_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "dev_offsets_forward_tracks_t",
    "dev_offsets_scifi_track_hit_number_t",
    "dev_scifi_track_hits_t",
    "dev_scifi_track_ut_indices_t",
    "dev_scifi_qop_t",
    "dev_scifi_states_t",
    "dev_is_muon_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_muon_validator"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_event_list_t,
    dev_velo_kalman_endvelo_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_track_hits_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    dev_offsets_forward_tracks_t,
    dev_offsets_scifi_track_hit_number_t,
    dev_scifi_track_hits_t,
    dev_scifi_track_ut_indices_t,
    dev_scifi_qop_t,
    dev_scifi_states_t,
    dev_is_muon_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_muon_validator_t"):
    self.__filename = "host/validators/include/HostMuonValidator.h"
    self.__name = name
    self.__original_name = "host_muon_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_endvelo_states_t", check_input_parameter(dev_velo_kalman_endvelo_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", check_input_parameter(dev_ut_track_hits_t, DeviceInput, "char")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("dev_offsets_forward_tracks_t", check_input_parameter(dev_offsets_forward_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_scifi_track_hit_number_t", check_input_parameter(dev_offsets_scifi_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_scifi_track_hits_t", check_input_parameter(dev_scifi_track_hits_t, DeviceInput, "char")),
      ("dev_scifi_track_ut_indices_t", check_input_parameter(dev_scifi_track_ut_indices_t, DeviceInput, "unsigned int")),
      ("dev_scifi_qop_t", check_input_parameter(dev_scifi_qop_t, DeviceInput, "float")),
      ("dev_scifi_states_t", check_input_parameter(dev_scifi_states_t, DeviceInput, "int")),
      ("dev_is_muon_t", check_input_parameter(dev_is_muon_t, DeviceInput, "bool")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_kalman_endvelo_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_endvelo_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def dev_offsets_forward_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_forward_tracks_t"]

  def dev_offsets_scifi_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_scifi_track_hit_number_t"]

  def dev_scifi_track_hits_t(self):
    return self.__ordered_parameters["dev_scifi_track_hits_t"]

  def dev_scifi_track_ut_indices_t(self):
    return self.__ordered_parameters["dev_scifi_track_ut_indices_t"]

  def dev_scifi_qop_t(self):
    return self.__ordered_parameters["dev_scifi_qop_t"]

  def dev_scifi_states_t(self):
    return self.__ordered_parameters["dev_scifi_states_t"]

  def dev_is_muon_t(self):
    return self.__ordered_parameters["dev_is_muon_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_pv_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "dev_event_list_t",
    "dev_multi_final_vertices_t",
    "dev_number_of_multi_final_vertices_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_pv_validator"

  def __init__(self,
    dev_event_list_t,
    dev_multi_final_vertices_t,
    dev_number_of_multi_final_vertices_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_pv_validator_t"):
    self.__filename = "host/validators/include/HostPVValidator.h"
    self.__name = name
    self.__original_name = "host_pv_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_multi_final_vertices_t", check_input_parameter(dev_multi_final_vertices_t, DeviceInput, "int")),
      ("dev_number_of_multi_final_vertices_t", check_input_parameter(dev_number_of_multi_final_vertices_t, DeviceInput, "unsigned int")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_multi_final_vertices_t"]

  def dev_number_of_multi_final_vertices_t(self):
    return self.__ordered_parameters["dev_number_of_multi_final_vertices_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_rate_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "host_names_of_lines_t",
    "host_number_of_active_lines_t",
    "dev_selections_t",
    "dev_selections_offsets_t",)
  outputs = ()
  props = (
    "verbosity",)
  aggregates = ()
  namespace = "host_rate_validator"

  def __init__(self,
    host_number_of_events_t,
    host_names_of_lines_t,
    host_number_of_active_lines_t,
    dev_selections_t,
    dev_selections_offsets_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    name="host_rate_validator_t"):
    self.__filename = "host/validators/include/HostRateValidator.h"
    self.__name = name
    self.__original_name = "host_rate_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("host_names_of_lines_t", check_input_parameter(host_names_of_lines_t, HostInput, "char")),
      ("host_number_of_active_lines_t", check_input_parameter(host_number_of_active_lines_t, HostInput, "unsigned int")),
      ("dev_selections_t", check_input_parameter(dev_selections_t, DeviceInput, "bool")),
      ("dev_selections_offsets_t", check_input_parameter(dev_selections_offsets_t, DeviceInput, "unsigned int"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def host_names_of_lines_t(self):
    return self.__ordered_parameters["host_names_of_lines_t"]

  def host_number_of_active_lines_t(self):
    return self.__ordered_parameters["host_number_of_active_lines_t"]

  def dev_selections_t(self):
    return self.__ordered_parameters["dev_selections_t"]

  def dev_selections_offsets_t(self):
    return self.__ordered_parameters["dev_selections_offsets_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_velo_ut_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_event_list_t",
    "dev_velo_kalman_endvelo_states_t",
    "dev_offsets_ut_tracks_t",
    "dev_offsets_ut_track_hit_number_t",
    "dev_ut_track_hits_t",
    "dev_ut_track_velo_indices_t",
    "dev_ut_qop_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_velo_ut_validator"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_event_list_t,
    dev_velo_kalman_endvelo_states_t,
    dev_offsets_ut_tracks_t,
    dev_offsets_ut_track_hit_number_t,
    dev_ut_track_hits_t,
    dev_ut_track_velo_indices_t,
    dev_ut_qop_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_velo_ut_validator_t"):
    self.__filename = "host/validators/include/HostVeloUTValidator.h"
    self.__name = name
    self.__original_name = "host_velo_ut_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("dev_velo_kalman_endvelo_states_t", check_input_parameter(dev_velo_kalman_endvelo_states_t, DeviceInput, "char")),
      ("dev_offsets_ut_tracks_t", check_input_parameter(dev_offsets_ut_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_ut_track_hit_number_t", check_input_parameter(dev_offsets_ut_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_ut_track_hits_t", check_input_parameter(dev_ut_track_hits_t, DeviceInput, "char")),
      ("dev_ut_track_velo_indices_t", check_input_parameter(dev_ut_track_velo_indices_t, DeviceInput, "unsigned int")),
      ("dev_ut_qop_t", check_input_parameter(dev_ut_qop_t, DeviceInput, "float")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def dev_velo_kalman_endvelo_states_t(self):
    return self.__ordered_parameters["dev_velo_kalman_endvelo_states_t"]

  def dev_offsets_ut_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_ut_tracks_t"]

  def dev_offsets_ut_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_ut_track_hit_number_t"]

  def dev_ut_track_hits_t(self):
    return self.__ordered_parameters["dev_ut_track_hits_t"]

  def dev_ut_track_velo_indices_t(self):
    return self.__ordered_parameters["dev_ut_track_velo_indices_t"]

  def dev_ut_qop_t(self):
    return self.__ordered_parameters["dev_ut_qop_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


class host_velo_validator_t(ValidationAlgorithm, metaclass=AlgorithmRepr):
  inputs = (
    "host_number_of_events_t",
    "dev_offsets_all_velo_tracks_t",
    "dev_offsets_velo_track_hit_number_t",
    "dev_velo_track_hits_t",
    "dev_event_list_t",
    "host_mc_events_t",)
  outputs = ()
  props = (
    "verbosity",
    "root_output_filename",)
  aggregates = ()
  namespace = "host_velo_validator"

  def __init__(self,
    host_number_of_events_t,
    dev_offsets_all_velo_tracks_t,
    dev_offsets_velo_track_hit_number_t,
    dev_velo_track_hits_t,
    dev_event_list_t,
    host_mc_events_t,
    verbosity=Property("int", "", "verbosity of algorithm"),
    root_output_filename=Property("int", "", "root output filename"),
    name="host_velo_validator_t"):
    self.__filename = "host/validators/include/HostVeloValidator.h"
    self.__name = name
    self.__original_name = "host_velo_validator_t"
    self.__ordered_parameters = OrderedDict([
      ("host_number_of_events_t", check_input_parameter(host_number_of_events_t, HostInput, "unsigned int")),
      ("dev_offsets_all_velo_tracks_t", check_input_parameter(dev_offsets_all_velo_tracks_t, DeviceInput, "unsigned int")),
      ("dev_offsets_velo_track_hit_number_t", check_input_parameter(dev_offsets_velo_track_hit_number_t, DeviceInput, "unsigned int")),
      ("dev_velo_track_hits_t", check_input_parameter(dev_velo_track_hits_t, DeviceInput, "char")),
      ("dev_event_list_t", check_input_parameter(dev_event_list_t, DeviceInput, "unsigned int")),
      ("host_mc_events_t", check_input_parameter(host_mc_events_t, HostInput, "const int *"))])
    self.__ordered_properties = OrderedDict([
      ("verbosity", Property("int", "", "verbosity of algorithm", verbosity)),
      ("root_output_filename", Property("int", "", "root output filename", root_output_filename))])

  def filename(self):
    return self.__filename

  def original_name(self):
    return self.__original_name

  def name(self):
    return self.__name

  def host_number_of_events_t(self):
    return self.__ordered_parameters["host_number_of_events_t"]

  def dev_offsets_all_velo_tracks_t(self):
    return self.__ordered_parameters["dev_offsets_all_velo_tracks_t"]

  def dev_offsets_velo_track_hit_number_t(self):
    return self.__ordered_parameters["dev_offsets_velo_track_hit_number_t"]

  def dev_velo_track_hits_t(self):
    return self.__ordered_parameters["dev_velo_track_hits_t"]

  def dev_event_list_t(self):
    return self.__ordered_parameters["dev_event_list_t"]

  def host_mc_events_t(self):
    return self.__ordered_parameters["host_mc_events_t"]

  def verbosity(self):
    return self.__ordered_properties["verbosity"]

  def root_output_filename(self):
    return self.__ordered_properties["root_output_filename"]

  def parameters(self):
    return self.__ordered_parameters

  def properties(self):
    return self.__ordered_properties

  def __repr__(self):
    s = self.__original_name + " \"" + self.__name + "\" ("
    for k, v in iter(self.__ordered_parameters.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    for k, v in iter(self.__ordered_properties.items()):
      s += "\n  " + k + " = " + repr(v) + ", "
    s = s[:-2]
    s += ")"
    return s


def algorithms_with_aggregates():
  return [gather_selections_t]


###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
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
                            parameters[parameter.fullname()].append(
                                (algorithm.name(), algorithm.namespace,
                                 parameter_t))
                        else:
                            parameters[parameter.fullname()] = [
                                (algorithm.name(), algorithm.namespace,
                                 parameter_t)
                            ]
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
                    s += " { using type = " + v[0][1] + "::Parameters::" + v[
                        0][2] + "::type; using deps = " + v[0][
                            1] + "::Parameters::" + v[0][2] + "::deps; };\n"

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
                s += prefix(
                    1) + algorithm.namespace + "::" + algorithm.original_name(
                    )
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
            # Generate get_sequence_algorithm_names function
            s += "constexpr auto sequence_algorithm_names = std::array{\n"
            i = len(self.__sequence)
            for _, algorithm in iter(self.__sequence.items()):
                s += prefix(1) + "\"" + algorithm.name() + "\""
                if i != 1: s += ",\n"
                i -= 1
            s += "};\n\n"
            # Generate populate_sequence_parameter_names
            s += "template<typename T>\nvoid populate_sequence_argument_names(T& argument_manager) {\n"
            i = 0
            for parameter_name in iter(parameters.keys()):
                s += prefix(
                    1
                ) + "argument_manager.template set_name<" + parameter_name + ">(\"" + parameter_name + "\");\n"
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
            for producer_filename in set([
                    self.__sequence[parameter.producer()].filename()
                    for _, parameter in parameters_part_of_aggregates.items()
            ]):
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
                s += " { using type = " + v[0][1] + "::Parameters::" + v[0][
                    2] + "::type; using deps = " + v[0][
                        1] + "::Parameters::" + v[0][2] + "::deps; };\n"

            s += "\n"
            for algorithm_with_aggregate_class in algorithms_with_aggregates_list:
                instance_of_alg_class = [
                    alg for _, alg in self.__sequence.items()
                    if type(alg) == algorithm_with_aggregate_class
                ]
                if len(instance_of_alg_class):
                    for algorithm in instance_of_alg_class:
                        for parameter_t, parameter_tup in iter(
                                algorithm.parameters().items()):
                            if type(parameter_tup) == tuple:
                                s += "namespace " + algorithm.namespace + " { namespace " + parameter_t + " { using tuple_t = std::tuple<"
                                for parameter in parameter_tup:
                                    s += parameter.fullname() + ", "
                                s = s[:-2] + ">; }}\n"
                else:
                    # Since there are no instances of that algorithm,
                    # at least we need to populate the aggregate inputs as empty
                    for aggregate_parameter in algorithm_with_aggregate_class.aggregates:
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
