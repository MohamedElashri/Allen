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
from __future__ import absolute_import, division, print_function
from collections import OrderedDict
import json

from enum import Enum


class DataObjectHandleBase(object):
    def __init__(self, name, mode, type):
        self.name_ = name
        self.mode_ = mode
        self.type_ = type

    def mode(self):
        return self.mode_

    def name(self):
        return self.name_

    def type(self):
        return self.type_


__all__ = [
    "dataflow_config",
    "DataHandleMode",
    "DataHandle",
    "configurable_inputs",
    "configurable_outputs",
    "is_datahandle_writer",
]


def _ensure_event_prefix(location):
    # FIXME
    # Gaudi prepends /Event to some locations on the C++ side, but not to all.
    # Until it is either added or left untouched by gaudi consistently, we
    # append it ourselves to ensure this consistence
    return location if location.startswith("/Event/") else "/Event/" + location


class dataflow_config(OrderedDict):
    """OrderedDict that becomes immutable after `apply` is called."""

    __readonly = False
    iovlockkey = "__IOVLock__"

    def apply(self):
        from .components import (
            setup_component,
            _is_configurable_tool,
            _is_configurable_algorithm,
        )

        self.__readonly = True
        configurable_algs = []
        configurable_tools = []
        for type_name, conf in self.items():
            type_, name = type_name
            IOV = conf.pop(self.iovlockkey, False)  # FIXME
            configurable = setup_component(
                type_, instanceName=name, IOVLockDep=IOV, **conf
            )
            if _is_configurable_algorithm(type_):
                configurable_algs.append(configurable)
            elif _is_configurable_tool(type_):
                configurable_tools.append(configurable)
            else:
                raise TypeError(
                    "{} wants to be configured but is neither of type AlgTool nor Algorithm".format(
                        type_
                    )
                )
        return configurable_algs, configurable_tools

    def print(self):
        try:
            print(json.dumps(self, indent=2))
        except TypeError:
            print(self)

    def __setitem__(self, k, v):
        if self.__readonly:
            raise TypeError("immutable")
        return OrderedDict.__setitem__(self, k, v)

    def __setattr__(self, k, v):
        if self.__readonly:
            raise TypeError("immutable")
        return OrderedDict.__setattr__(self, k, v)

    def __delitem__(self, i):
        if self.__readonly:
            raise TypeError("immutable")
        return OrderedDict.__delitem__(self, i)

    def __delattr__(self, a):
        if self.__readonly:
            raise TypeError("immutable")
        return OrderedDict.__delattr__(self, a)


class DataHandleMode(Enum):
    READER = "R"
    WRITER = "W"
    UPDATER = "RW"


class DataHandle(object):
    """A representation for an input/output of an Algorithm."""

    def __init__(self, producer, key, custom_location=None):
        from .components import is_algorithm, force_location

        if not producer or not key:
            raise ValueError("producer or key not set correctly")
        if not is_algorithm(producer):
            raise TypeError("producer not of type Algorithm")

        self._producer = producer  # of type algorithm
        self._key = key
        if isinstance(custom_location, force_location):
            self._force_location = True
            self._custom_location = str(custom_location)
        else:
            self._force_location = False
            self._custom_location = custom_location

        self._id = hash(str(self.producer.id) + "_" + self.key)

        if not self._custom_location:
            self._location = self.producer.name + "/" + self.key
        else:
            self._location = self._custom_location
            if not self._force_location:
                self._location += "/" + str(self.producer.id)  # TODO review

    @property
    def location(self):
        return _ensure_event_prefix(
            self._location
        )  # FIXME see _ensure_event_prefix description

    def __eq__(self, other):
        return self.id == other.id

    @property
    def producer(self):
        return self._producer

    @property
    def key(self):
        return self._key

    @property
    def id(self):
        return self._id

    @property
    def force_location(self):
        return self._force_location

    @property
    def type(self):
        """Return the representation of the underlying C++ type.

        Returns:
            str: The C++ type if the our producer represents the property with
            a C++ DataHandle, otherwise "unknown_t".
        """
        props = self._producer.type.getDefaultProperties()
        try:
            return props[self._key].type()
        except KeyError:
            return "unknown_t"

    def __repr__(self):
        return "DataHandle({!r})".format(self.location)

    def __hash__(self):
        return self._id


def is_datahandle(arg):
    """Returns True if arg is of type DataHandle"""
    return isinstance(arg, DataHandle)


def is_datahandle_writer(x):
    """Return True if x is a writer DataHandle or a list of them.

    Returns False if x is an empty list.
    """
    if not isinstance(x, list):
        x = [x]
    # Ignore empty lists, then check that all elements are DataHandle writers
    return (
        False
        if not x
        else all(
            isinstance(i, DataObjectHandleBase)
            and i.mode() != DataHandleMode.READER.value
            for i in x
        )
    )


def configurable_outputs(alg_type):
    """Return a list of all output properties of alg_type."""
    return [
        key
        for key, val in alg_type.getDefaultProperties().items()
        if is_datahandle_writer(val)
    ]


def configurable_inputs(alg_type):
    """Return a list of all input properties of alg_type."""
    return {
        key: val
        for key, val in alg_type.getDefaultProperties().items()
        if (
            isinstance(val, DataObjectHandleBase)
            and val.mode() != DataHandleMode.WRITER.value
        )
    }

def get_dependencies(alg):
    return list(alg.all_producers(include_optionals=False))
    