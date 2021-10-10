###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
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
    def __init__(self, scope, *args, **kwargs):
        super(AllenDataHandle, self).__init__(*args, **kwargs)
        self.Scope = scope

    def __getstate__(self):
        return super(AllenDataHandle, self).__getstate__()

    def __setstate__(self, state):
        return super(AllenDataHandle, self).__setstate__(state)

    def __eq__(self, other):
        return super(AllenDataHandle, self).__eq__(other)

    def __ne__(self, other):
        return super(AllenDataHandle, self).__ne__(other)

    def __str__(self):
        return super(AllenDataHandle, self).__str__()

    def __repr__(self):
        return super(AllenDataHandle, self).__repr__()
