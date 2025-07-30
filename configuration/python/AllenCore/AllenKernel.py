###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from collections import OrderedDict
from PyConf.dataflow import GaudiDataHandle


class AllenAlgorithm(object):
    _all_algs = OrderedDict()

    def __new__(cls, name, **kwargs):
        i = super(AllenAlgorithm, cls).__new__(cls)
        for k, v in iter(cls.__slots__.items()):
            setattr(i, k, v)
        cls._all_algs[name] = i
        return cls._all_algs[name]

    @classmethod
    def getGaudiType(cls):
        return 'Algorithm'

    @classmethod
    def getDefaultProperties(cls):
        return cls.__slots__


class AllenDataHandle(GaudiDataHandle):
    def __init__(self, scope, dependencies, *args, **kwargs):
        super(AllenDataHandle, self).__init__(*args, **kwargs)
        self.Scope = scope
        self.Dependencies = dependencies
