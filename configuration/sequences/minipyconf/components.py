###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Wrappers and helpers for Configurable algorithms and tools.

There are three core components that are provided for defining a dataflow:

    1. Algorithm
    2. Tool
    3. DataHandle

DataHandles are inputs and outputs of Algorithms and Tools.
"""
from __future__ import absolute_import, division, print_function
from collections import OrderedDict, defaultdict
try:
    from html import escape as html_escape
except ImportError:
    from cgi import escape as html_escape
import inspect
import re
import json
import importlib

import pydot

from . import ConfigurationError
from .dataflow import DataHandle, configurable_outputs, configurable_inputs, dataflow_config, is_datahandle

__all__ = [
    'Algorithm',
    'Tool',
    'force_location',
    'is_algorithm',
    'is_tool',
    'setup_component',
]

# String that separates a name from its unique ID
_UNIQUE_SEPARATOR = '#'
_UNIQUE_PREFIXES = defaultdict(lambda: 0)

_FLOW_GRAPH_NODE_COLOUR = 'aliceblue'
_FLOW_GRAPH_INPUT_COLOUR = 'deepskyblue1'
_FLOW_GRAPH_OUTPUT_COLOUR = 'coral1'


def _json_dump(obj):
    """Return the value of `obj.to_json()`.

    The typical use-case is for dumping `BoundFunctor` and derived objects.

    Args:
        obj: Object with a `to_json` method member.

    Raises:
        TypeError: If `obj.to_json` raises an AttributeError.
    """
    try:
        return obj.to_json()
    except AttributeError:
        raise TypeError(repr(obj) + " is not json serializable")


def _hash_dict(d):
    """Return the hash of the dict `d`.

    Args:
        d (dict or object supported by `_json_dump`): Object to be serialised.
    """
    return hash(json.dumps(d, default=_json_dump, sort_keys=True))


def _get_args(func):
    """get the argument keys of a function"""
    return inspect.getargspec(func).args


def _safe_name(string):
    """Return `string` with :: replaced with __."""
    if not string:
        return
    return string.replace('::', '__')


def _get_unique_name(prefix=''):
    """Return `prefix` appended with a unique ID.

    The ID is related to the value of `prefix` and is incremented each time
    this function is called. If the `prefix` value has not been seen before no
    ID is appended.
    """
    i = _UNIQUE_PREFIXES[prefix]
    _UNIQUE_PREFIXES[prefix] += 1
    return prefix + (_UNIQUE_SEPARATOR + str(i) if i > 0 else "")


def _strip_unique_from(name):
    """Return `name` with the unique suffix removed.

    The suffix added by `_get_unique_name`.
    """
    return re.sub(_UNIQUE_SEPARATOR + r"\d*", "", name)


def _is_configurable_algorithm(t):
    try:
        return t.getGaudiType() == 'Algorithm'
    except AttributeError:
        return False


def _is_configurable_tool(t):
    try:
        return t.getGaudiType() == 'AlgTool'
    except AttributeError:
        return False


def _check_input_integrity(t, inputs, other_args, input_transform=None):
    dh_inputs = configurable_inputs(t)

    # Exclude masks (inputs with type mask_t) from the DataHandle inputs to consider
    dh_inputs = set(d for d, v in dh_inputs.items() if v.type() != "mask_t")
    inputs = set(inputs)

    if set(dh_inputs).intersection(other_args):
        raise TypeError(
            'Inputs must be provided as DataHandles or Algorithms, '
            'please check these arguments: {}'.format(dh_inputs))
    if not set(dh_inputs).issubset(inputs):
        raise ConfigurationError(
            'Please provide all inputs. The ones need here are: {}, while you only give {}'.format(
                dh_inputs, set(inputs)))
    if input_transform:
        input_transform_args = _get_args(input_transform)
        assert set(inputs).issubset(
            input_transform_args), 'input signatures do not match'


def _ids_from_list(handles):
    """Return a tuple of IDs of the input data handles.

    If a single handle is passed, a one-tuple of its ID is returned.
    """
    handles = handles if isinstance(handles, list) else [handles]
    return tuple(h.id for h in handles)


def _gather_locations(io_dict):
    """Return the dictionary with all values mapped to their `.location` property.

    Lists values have `.location` accessed on each of their members.
    """
    d = {}
    for k, v in io_dict.items():
        if isinstance(v, list):
            d[k] = [vv.location for vv in v]
        else:
            d[k] = v.location
    return d


def _gather_tool_names(tool_dict):
    """Return the dictionary with all values mapped to their `.property_name` property.

    Lists values have `.property_name` accessed on each of their members.
    """
    d = {}
    for k, v in tool_dict.items():
        if isinstance(v, list):
            d[k] = [vv.property_name for vv in v]
        else:
            d[k] = v.property_name
    return d


def is_algorithm(arg):
    """Returns True if arg is of type Algorithm"""
    return isinstance(arg, Algorithm)


def contains_tool(arg):
    """Return True if arg is a Tool or list of Tools, or list of list of tools etc."""
    return is_tool(arg) or _is_list_of_tools(arg)


def _is_list_of_tools(iterable):
    """Return True if all elements are Tool instances.

    Returns False if the iterable is empty.
    """
    return False if not iterable else (isinstance(iterable, list)
                                       and all(map(contains_tool, iterable)))


def is_tool(arg):
    """Return True if arg is a Tool."""
    return isinstance(arg, Tool)


def _is_input(arg):
    """Return True if arg is something that produces output."""
    arg = arg if isinstance(arg, list) else [arg]
    return all(map(is_datahandle, map(_get_output, arg)))


def _get_output(arg):
    """Return the single output defined on arg.

    Raises an AssertionError if arg is an Algorithm with multiple outputs.
    """
    if is_algorithm(arg):
        outputs = arg.outputs.values()
        assert len(outputs) == 1, 'Expected a single output on {}'.format(arg)
        try:
            return outputs[0]
        except KeyError:
            # outputs is a dict, so return the first and only value
            return outputs.values()[0]
    return arg


def _pop_inputs(props):
    """Return a dict of all properties that are inputs or lists of inputs."""
    inputs = OrderedDict()
    blub = list(props.items())
                
    for k, v in blub:
        if _is_input(v):
            inp = props.pop(k)
            if isinstance(inp, list):
                inp = list(map(_get_output, inp))
            else:
                inp = _get_output(inp)
            inputs[k] = inp

    return inputs

def _is_optional(key, alg_type):
    if hasattr(alg_type, "aggregates"): #TODO change this logic
        return key in alg_type.aggregates
    return False

def _gather_optionals(inputs, alg_type):
    dh_inputs = configurable_inputs(alg_type)
    optionals = set()
    for key in inputs:
        if key in dh_inputs and _is_optional(key, alg_type):
            optionals.add(key)
    return optionals
        

def _pop_tools(props):
    """Return a dict of all properties that are Tools.

    Raises a TypeError if a tool is not wrapped by our Tool class (e.g. a bare
    Configurable).
    """
    tools = OrderedDict()
    blub = props.items()
    for k, v in blub:
        if contains_tool(v):
            tools[k] = props.pop(k)
        elif _is_configurable_tool(v):
            raise TypeError(" ".join((
                "Please either wrap your configurable with the PyConf.components.Tool wrapper",
                "or import it from PyConf.Tools if possible")))
    return tools


def _get_and_check_properties(t, props):
    """Return an OrderedDict of props.

    Raises a ConfiguurationError if any of the keys in props are not
    properties of the Algorithm/Tool t.
    """
    missing = [p for p in props if p not in t.getDefaultProperties()]
    if missing:
        raise ConfigurationError('{} are not properties of {}'.format(
            missing, t.getType()))
    return OrderedDict(props)


def _format_property(name, value, max_len=100, placeholder="[...]"):
    assert max_len > 15, "max_len should be at least 15"
    # If it's a functor, display it's pretty representation, otherwise convert
    # to str
    try:
        value = value.code_repr()
    except AttributeError:
        value = str(value)
    if len(value) > (max_len + len(placeholder)):
        pivot = max_len // 2
        value = "{}{}{}".format(value[:pivot], placeholder, value[-pivot:])
    return '{} = {}'.format(name, value)


class force_location(str):
    """An indicator that a location must be set as defined.

    Algorithm output locations are usually appended by a hash defined that
    algorithm's properties and inputs. By wrapping an output DataHandle in
    `force_location`, this appending is not done.

    You almost never want to use this. Notable exceptions include the outputs
    of legacy unpacking algorithms, which must be defined exactly else
    SmartRefs pointing to those locations will break.
    """
    pass


class Algorithm(object):
    """An immutable wrapper around a Configurable for a Gaudi algorithm.

    An Algorithm is immutable after instantiation, so all non-default
    properties and inputs must be defined upfront. A name can be given but is
    used only as a label, not an identifier.

    Output locations are defined dynamically using a combination of the
    algorithm class name and a hash that is generated based on the algorithm
    properties and inputs. Instanting a new Algorithm that is configured
    identically to a previous Algorithm will result in the same first instance
    being returned.

    Importing Configurable classes from the `PyConf.Algorithms` module will
    return a version wrapped by this class.
    """
    _algorithm_store = dict()

    _readonly = False

    def __new__(cls,
                alg_type,
                name=None,
                outputs=None,
                input_transform=None,
                output_transform=None,
                require_IOVLock=True,
                weight = 1,
                **kwargs):
        """
        Args:
            alg_type: the configurable you want to be instantiated
            name: The name to be used for the algorithm. A hash will be appended.
            outputs:
                A complete collection of outputs. This is not mandatory if
                the alg_type corresponds to an Algorithm where all outputs
                are declared via DataHandles.
                outputs can either be a list of keys ['OutputLocation1', 'OutputLocation2'],
                in case you want the framework to set locations for you.
                If you want your own locations, use a dictionary:
                {'OutputLocation1' : '/Event/OutputLocation1', ...}
                In this case, the given location will be used,
                but with a hash (to guarantee it's unique).
                In case you want to force the exact location to be used,
                wrap the location with 'force_location':
                {'OutputLocation1' : force_location('/Event/OutputLocation1'), ...}
                This might induce failures, since we rely on unique locations.
                It is not recommended, and if you use it, assure unique locations yourself!
            input_transform:
                A function to transform inputkeys/locations into actual properties.
                In case your input locations are translated into properties differently than
                {'input_key' : '<location>'},
                for instance in LoKi Functors:
                {'CODE' : 'SIZE('<location>'},
                you can specify the behaviour in input_transform.
                The arguments for input_transform are all the input keys, and the output is a
                dictionary of the resulting actual properties:
                Example: Some alg has two inputs called 'Input1' and 'Input2', and needs these
                locations to go into the 'CODE' property to check for the bank sizes
                def input_transform_for_some_alg(Input1, Input2):
                    return {'CODE' : 'SIZE({}) > 5 & SIZE({}) < 3'.format(Input1, Input2)}
            output_transform:
                Similar to input_transform.
                The output_transform arguments need to match the outputs in case you provide both.
                In case you provide only output_transform, the arguments will be used to deduce the property 'outputs'.

                output_transform functions are not allowed to modify the string
                that is interpreted as the location. They may only define how a
                location is put into the job options.
                Examples:

                1. Not allowed, as it changes the output path:

                    def transform(output):
                        return {'Output': output + '/Particles'}

                2. OK, the location is used in a LoKi functor:

                    def transform(output):
                        return {'Code': 'SIZE({})'.format(output)}

                3. OK, the location is used in a list:

                    def transform(output):
                        return {'DataKeys': [output]}

            kwargs:
                All the properties you want to set in the configurable (besides outputs)
                Every kwarg that has a DataHandle as value will be interpreted as input and
                the list of inputs needs to match the signature of 'input_transform', in case you provide it.
                Every input needs to be provided in the kwargs
                Every kwarg that has a Tool as value will be interpreted as private tool of this instance.
                Tools that have some kind of TES interation (or tools of these tools) need to be
                specified, otherwise the framework cannot know what locations to set.

        returns:
            instance of type Algorithm. It can be taken from the class store
            in case it has already been instantiated with the same configuration
        """
        if not _is_configurable_algorithm(alg_type):
            raise TypeError(
                'cannot declare an Algorithm with {}, which is of type {}'.
                format(alg_type, alg_type.getGaudiType()))

        #INPUTS ###########
        # TODO when everything is functional, input keys can be checked!
        _inputs = _pop_inputs(kwargs)
        _check_input_integrity(alg_type, _inputs, kwargs, input_transform)

        # We normally assume that an algorithms properties and input locations
        # fully define its behaviour, but when the user forces an output
        # location this forms part of the algorithm's defined behaviour
        # So, record when any output location is forced
        if isinstance(outputs, dict):
            forced_locations = {
                key: str(output)
                for key, output in outputs.items()
                if isinstance(output, force_location)
            }
        else:
            forced_locations = dict()

        #TOOLS ##############
        _tools = _pop_tools(kwargs)

        #PROPERTIES ############
        _properties = _get_and_check_properties(alg_type, kwargs)

        #HASH ###########
        identity = cls._calc_id(alg_type.getType(), _properties, _inputs,
                                _tools, input_transform, forced_locations)

        # return the class if it exists already, otherwise create it
        try:
            instance = cls._algorithm_store[identity]
            if name and _strip_unique_from(instance._name) != name:
                raise ConfigurationError(
                    "cannot instantiate the same algorithm twice with different names ({} and {})"
                    .format(_strip_unique_from(instance._name), name))
        except KeyError:
            instance = super(Algorithm, cls).__new__(cls)

            # __init__ basically
            instance._id = identity
            instance._weight = weight
            instance._alg_type = alg_type
            instance._name = _get_unique_name(name or alg_type.getType())
            instance._inputs = _inputs
            instance._optional_inputs = _gather_optionals(_inputs, alg_type)
            instance._input_transform = input_transform
            instance._output_transform = output_transform
            instance._properties = _properties
            instance._requireIOV = require_IOVLock
            instance._tools = _tools
            instance._outputs_define_identity = bool(forced_locations)

            #make OUTPUTS ############# these were not needed for calculation of the ID (only the forced locations)
            def _make_outs(outputs):
                # special behaviour if outputs is a dict: let them have readable locations
                # with force_location you can force this exact location (unsafe, usecase rawevent)
                if isinstance(outputs, dict):
                    return {
                        k: DataHandle(instance, k, v)
                        for k, v in outputs.items()
                    }
                return {k: DataHandle(instance, k) for k in outputs}

            instance._outputs = {}
            if outputs:
                instance._outputs = _make_outs(outputs)
            if instance._output_transform:
                output_transform_args = _get_args(instance._output_transform)
                if not outputs:
                    instance._outputs = _make_outs(output_transform_args)
                else:
                    assert set(output_transform_args).issubset(
                        instance._outputs), 'output signatures do not match'

            if not instance._outputs:
                # neither explicit outputs nor a transform was set
                # we can still deduce from functional signature (hopefully)
                instance._outputs = _make_outs(
                    configurable_outputs(instance.type))

            for o in instance._outputs:
                if o in kwargs:
                    raise ConfigurationError(
                        "Cannot set output property {} explicitly. \
                                          Please configure the 'outputs' property correctly."
                        .format(o))

            for key, src in instance._outputs.items():
                setattr(instance, key, src)

            # Configuration cache
            instance._configuration = instance._calc_configuration()

            instance._readonly = True
            cls._algorithm_store[identity] = instance
        #return the cached or new instance
        return instance

    @staticmethod
    def _calc_id(typename,
                 props,
                 inputs,
                 tools,
                 input_transform=None,
                 forced_outputs=None):
        if forced_outputs is None:
            forced_outputs = dict()
        props_hash = _hash_dict(props)
        if input_transform is not None:
            props_from_transform = input_transform(**_gather_locations(inputs))
        else:
            props_from_transform = {}
        input_transform_hash = _hash_dict(props_from_transform)
        inputs_hash = _hash_dict(
            {key: _ids_from_list(handles)
             for key, handles in inputs.items()})
        tools_hash = _hash_dict(
            {key: _ids_from_list(tool)
             for key, tool in tools.items()})
        outputs_hash = _hash_dict(forced_outputs)
        to_be_hashed = (typename, props_hash, inputs_hash, tools_hash,
                        outputs_hash, input_transform_hash)
        return hash(to_be_hashed)

    # end of __init__

    @property
    def inputs(self):
        return self._inputs

    @property
    def optional_input_keys(self):
        return self._optional_inputs

    def all_producers(self, include_optionals=True):
        """Return the set of all direct and indirect producers of this algorithm."""
        processed_producers = set()
        current_producers = set([self])
        next_producers = set()

        while len(current_producers):
            for producer in current_producers:
                for inp in [val for key, val in producer.inputs.items() if include_optionals or key not in self.optional_input_keys]:
                    if isinstance(inp, list):
                        for single_input in inp:
                            next_producers.add(single_input.producer)
                    else:
                        next_producers.add(inp.producer)
            processed_producers.update(current_producers)
            current_producers = next_producers.difference(processed_producers)
            next_producers = set()
        return processed_producers

    @property
    def all_inputs(self):
        """Return the set of all direct and indirect inputs of this algorithm."""
        inputs = set()
        producers = self.all_producers()
        for producer in producers:
            for inp in producer.inputs.values():
                if isinstance(inp, list):
                    for single_input in inp:
                        inputs.add(single_input)
                else:
                    inputs.add(inp)
        for inp in self.inputs.values():
            if isinstance(inp, list):
                for single_input in inp:
                    inputs.add(inp)
            else:
                inputs.add(inp)
        return inputs

    @property
    def outputs(self):
        return self._outputs

    @property
    def properties(self):
        return self._properties

    @property
    def name(self):
        return _safe_name(self._name)

    @property
    def fullname(self):
        return self.typename + '/' + self.name

    @property
    def id(self):
        return self._id

    @property
    def type(self):
        return self._alg_type

    @property
    def tools(self):
        return self._tools

    @property
    def typename(self):
        return _safe_name(self.type.getType())

    def __repr__(self):
        return self.fullname

    def __hash__(self):
        return self.id

    def __eq__(self, other):
        return self.id == other.id

    def tool_inputs(self):
        """Return the transitive closure of tool inputs."""

        def _inputs_from_tool(tool):
            if isinstance(tool, list):
                inputs = OrderedDict()
                for t in tool:
                    inputs.update(_inputs_from_tool(t))
            else:
                inputs = {tool.name(self.name): tool.inputs}
                for _tool in tool.tools.values():
                    inputs.update(_inputs_from_tool(_tool))
            return inputs

        all_inputs = OrderedDict()
        for tool in self.tools.values():
            all_inputs.update(_inputs_from_tool(tool))
        return all_inputs

    def _calc_configuration(self):
        config = dataflow_config()

        #children
        for inputs in self.inputs.values():
            inputs = inputs if isinstance(inputs, list) else [inputs]
            for inp in inputs:
                config.update(inp.producer.configuration())

        for tool in self.tools.values():
            tool = tool if isinstance(tool, list) else [tool]
            for t in tool:
                config.update(t.configuration(self.name))

        #props
        cfg = config[(self.type, self.name)] = self.properties.copy()
        cfg[config.iovlockkey] = self._requireIOV  # FIXME

        #io
        input_dict = _gather_locations(self.inputs)
        output_dict = _gather_locations(self.outputs)

        if self._input_transform:
            input_dict = self._input_transform(**input_dict)

        if self._output_transform:
            output_dict = self._output_transform(**output_dict)

        cfg.update(input_dict)
        cfg.update(output_dict)

        #tools
        tools_dict = _gather_tool_names(self.tools)
        cfg.update(tools_dict)

        return config

    def configuration(self):
        return self._configuration

    def _graph(self, graph, visited=None):
        """Add our dataflow as a `pydot.Subgraph` to graph.

        The `visited` set keeps a flat record of components already drawn in
        `graph` and all subgraphs. This is done to prevent re-drawing
        components that have already been drawn, which can occur due to diamond
        structures in the dependency tree.

        Args:
            graph (pydot.Graph): Graph to draw this component in to.
            visited (set): Names of components already drawn in `graph`. If
            `None`, an empty set is used.
        """
        if visited is None:
            visited = set()
        if self.fullname in visited:
            return
        else:
            visited.add(self.fullname)

        #inner part ########
        own_name = html_escape(self.fullname)
        sg = pydot.Subgraph(graph_name='cluster_' + own_name)
        sg.set_label('')
        sg.set_bgcolor(_FLOW_GRAPH_NODE_COLOUR)

        props = self.properties
        # Include output locations when they define algorithm behaviour
        if self._outputs_define_identity:
            output_props = {k: v.location for k, v in self._outputs.items()}
            props = dict(props.items() + output_props.items())
        props_str = '<BR/>'.join(
            html_escape(_format_property(k, v)) for k, v in props.items())
        label = ('<<B>{}</B><BR/>{}>'.format(own_name, props_str
                                             or 'defaults-only'))
        # Protect against names that may contain colons (e.g. from C++
        # namespaces in algorithm/tool names)
        # https://github.com/pydot/pydot/issues/38
        gnode = pydot.Node(
            '"{}"'.format(own_name), label=label, shape='plaintext')
        sg.add_node(gnode)

        #IO for the inner part
        for name in self.inputs:
            input_id = html_escape('{}_in_{}'.format(self.fullname, name))
            node = pydot.Node(
                '"{}"'.format(input_id),
                label=html_escape(name),
                fillcolor=_FLOW_GRAPH_INPUT_COLOUR,
                style='filled')
            edge = pydot.Edge(gnode, node, style='invis', minlen='0')
            sg.add_node(node)
            sg.add_edge(edge)
        for name in self.outputs:
            output_id = html_escape('{}_out_{}'.format(self.fullname, name))
            node = pydot.Node(
                '"{}"'.format(output_id),
                label=html_escape(name),
                fillcolor=_FLOW_GRAPH_OUTPUT_COLOUR,
                style='filled')
            edge = pydot.Edge(gnode, node, style='invis', minlen='0')
            sg.add_node(node)
            sg.add_edge(edge)

        # tool inputs
        tool_inputs = self.tool_inputs()

        for toolname, inputs in tool_inputs.items():
            for name in inputs:
                input_id = html_escape('{}_in_{}'.format(toolname, name))
                label = ('<<B>{}</B><BR/>from {}>'.format(
                    html_escape(name), html_escape(toolname)))
                node = pydot.Node(
                    '"{}"'.format(input_id),
                    label=label,
                    fillcolor=_FLOW_GRAPH_INPUT_COLOUR,
                    style='filled')
                edge = pydot.Edge(
                    input_id, own_name, style='invis', minlen='0')
                sg.add_node(node)
                sg.add_edge(edge)

        graph.add_subgraph(sg)

        # external links #######
        for key, handles in self.inputs.items():
            handles = handles if isinstance(handles, list) else [handles]
            for handle in handles:
                edge = pydot.Edge(
                    html_escape('{}_out_{}'.format(handle.producer.fullname,
                                                   handle.key)),
                    html_escape('{}_in_{}'.format(self.fullname, key)))
                graph.add_edge(edge)
                handle.producer._graph(graph, visited)

        for toolname, inputs in tool_inputs.items():
            for name, handle in inputs.items():
                edge = pydot.Edge(
                    html_escape('{}_out_{}'.format(handle.producer.fullname,
                                                   handle.key)),
                    html_escape('{}_in_{}'.format(toolname, name)))
                graph.add_edge(edge)
                handle.producer._graph(graph, visited)

    def plot_dataflow(self):
        """Return a `pydot.Dot` of the dataflow defined by this Algorithm."""
        top = pydot.Dot(graph_name=self.fullname, strict=True)
        top.set_node_defaults(shape='box')
        self._graph(top)
        return top

    def __setitem__(self, k, v):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__setitem__(self, k, v)

    def __setattr__(self, k, v):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__setattr__(self, k, v)

    def __delitem__(self, i):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__delitem__(self, i)

    def __delattr__(self, a):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__delattr__(self, a)


class Tool(object):
    """An immutable wrapper around a Configurable for a Gaudi tool.

    A Tool is immutable after instantiation, so all non-default properties and
    inputs must be defined upfront. A name can be given but is used only as a
    label, not an identifier.

    Instanting a new Tool that is configured identically to a previous
    Tool will result in the same first instance being returned.

    Importing Configurable classes from the `PyConf.Tools` module will return a
    version wrapped by this class.
    """

    _tool_store = dict()

    _readonly = False

    def __new__(cls, tool_type, name=None, public=False, **kwargs):
        """
        Args:
            tool_type: the configurable you want to be instantiated
            name: The name to be used for the Tool. A hash will be appended.
            public: True if the tool will belong to the ToolSvc, False
                otherwise (i.e. the tool is 'private'; unique Configurable
                instances will be given to individual algorithms).
            kwargs:
                All the properties you want to set in the configurable (besides outputs)
                Every kwarg that has a DataHandle as value will be interpreted as input.
                Every input needs to be provided in the kwargs.
                Every kwarg that has a Tool as value will be interpreted as private tool of this instance.
                Tools that have some kind of TES interation (or tools of these tools) need to be
                specified, otherwise the framework cannot know what locations to set.
        returns:
            instance of type Tool, maybe taken from the tool store (in case of same configuration)
        """
        if not _is_configurable_tool(tool_type):
            raise TypeError(
                'cannot declare a Tool with {}, which is of type {}'.format(
                    tool_type, tool_type.getGaudiType()))

        #inputs
        _inputs = _pop_inputs(kwargs)
        _check_input_integrity(tool_type, _inputs, kwargs)

        #tools
        _tools = _pop_tools(kwargs)

        #properties
        _properties = _get_and_check_properties(tool_type, kwargs)

        #calculate the id, this determines whether we can take an already created instance
        identity = cls._calc_id(tool_type.getType(), _properties, _inputs,
                                _tools)
        try:
            instance = cls._tool_store[identity]
            if name and _strip_unique_from(instance._name) != name:
                raise ConfigurationError(
                    "cannot instantiate the same tool twice with different names"
                )
        except KeyError:
            instance = super(Tool, cls).__new__(cls)
            instance._id = identity
            instance._tool_type = tool_type
            instance._name = _get_unique_name(name or tool_type.getType())
            instance._public = public
            instance._inputs = _inputs
            instance._optional_inputs = _gather_optionals(_inputs, tool_type)
            instance._properties = _properties
            instance._tools = _tools
            instance._readonly = True
            cls._tool_store[identity] = instance
        return instance

    def _valid_with_parent(self, parent):
        """Return True if this tool's configuration is valid given the parent.

        A `parent` value of None is only valid is this tool is public. A
        non-None value is only valid if this tool is private.
        """
        if self.public:
            return parent is None
        else:
            return parent is not None

    @staticmethod
    def _calc_id(typename, props, inputs, tools):
        props_hash = _hash_dict(props)
        inputs_hash = _hash_dict(
            {key: _ids_from_list(handles)
             for key, handles in inputs.items()})
        tools_hash = _hash_dict(
            {key: _ids_from_list(tool)
             for key, tool in tools.items()})
        to_be_hashed = (typename, props_hash, inputs_hash, tools_hash)
        return hash(to_be_hashed)

    @property
    def public(self):
        """Return True if this tool is public.

        A private tool is configured uniquely in association with a specific
        algorithm, to which it belongs.
        """
        return self._public

    @property
    def private(self):
        """Return True if this tool is private.

        A public tool is configured uniquely in association with the ToolSvc,
        to which it belongs.
        """
        return not self.public

    @property
    def inputs(self):
        return self._inputs

    @property
    def properties(self):
        return self._properties

    @property
    def id(self):
        return self._id

    @property
    def tools(self):
        return self._tools

    @property
    def property_name(self):
        #how instances refer to their tools
        return self.typename + '/' + self._name

    def name(self, parent=None):
        """Configuration name of the tool itself.

        If the tool is public, `parent` must be None and the name will be
        prepended with `ToolSvc`, otherwise the name will be prepended with
        `parent`.
        """
        if not self._valid_with_parent(parent):
            raise ConfigurationError("Parent unspecified for a private tool")

        return "{}.{}".format(parent or "ToolSvc", self._name)

    @property
    def type(self):
        return self._tool_type

    @property
    def typename(self):
        return self.type.getType()

    def __repr__(self):
        return 'Tool({})'.format(self.typename)

    def __hash__(self):
        return self.id

    def __eq__(self, other):
        return self.id == other.id

    def configuration(self, parent=None):
        if not self._valid_with_parent(parent):
            raise ConfigurationError("Parent unspecified for a private tool")

        name = self.name(parent)
        config = dataflow_config()

        for inputs in self.inputs.values():
            inputs = inputs if isinstance(inputs, list) else [inputs]
            for inp in inputs:
                config.update(inp.producer.configuration())

        for tool in self.tools.values():
            tool = tool if isinstance(tool, list) else [tool]
            for t in tool:
                config.update(t.configuration(name))

        cfg = config[(self.type, name)] = self.properties.copy()
        input_dict = _gather_locations(self.inputs)
        cfg.update(input_dict)

        tools_dict = _gather_tool_names(self.tools)
        cfg.update(tools_dict)

        return config

    def __setitem__(self, k, v):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__setitem__(self, k, v)

    def __setattr__(self, k, v):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__setattr__(self, k, v)

    def __delitem__(self, i):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__delitem__(self, i)

    def __delattr__(self, a):
        if self._readonly:
            raise ConfigurationError(
                'cannot change member after initialization')
        return object.__delattr__(self, a)


def setup_component(alg,
                    instanceName=None,
                    packageName='Configurables',
                    IOVLockDep=False,
                    **kwargs):
    """Return an instance of the class alg.

    If alg is a string, import the named class from packageName.

    If IOVLockDep is True, a dependency on `/Event/IOVLock` is added to the
    instance's ExtraInputs property.

    Additional keyword arguments are forwarded to the alg constructor.
    """
    if isinstance(alg, str):
        imported = getattr(importlib.import_module(packageName), alg)
        instance = imported((instanceName or alg), **kwargs)
        if IOVLockDep and hasattr(
                instance, 'ExtraInputs'
        ) and '/Event/IOVLock' not in instance.ExtraInputs:
            instance.ExtraInputs.append('/Event/IOVLock')  # FIXME
        return instance
    else:
        return alg((instanceName or alg.name()), **kwargs)
