###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.dataflow import GaudiDataHandle
from AllenConf.AllenKernel import AllenAlgorithm
from collections import OrderedDict
from enum import Enum


def algorithm_dict(*algorithms):
    d = OrderedDict([])
    for alg in algorithms:
        d[alg.name] = alg
    return d


class AlgorithmCategory(Enum):
    HostAlgorithm = 0
    DeviceAlgorithm = 1
    SelectionAlgorithm = 2
    HostDataProvider = 3
    DataProvider = 4


class host_init_event_list_t(AllenAlgorithm):
    __slots__ = OrderedDict(
        host_event_list_output_t=GaudiDataHandle(
            "host_event_list_output_t", "W", "unsigned int"),
        dev_event_list_output_t=GaudiDataHandle("dev_event_list_output_t",
                                                     "W", "mask_t"),
        verbosity="")
    aggregates = ()

    @staticmethod
    def category():
        return AlgorithmCategory.HostAlgorithm

    def __new__(self, name, **kwargs):
        instance = AllenAlgorithm.__new__(self, name)
        for n, v in kwargs.items():
            setattr(instance, n, v)
        return instance

    @classmethod
    def namespace(cls):
        return "host_init_event_list"

    @classmethod
    def filename(cls):
        return "/home/nn/Allen/host/init_event_list/include/HostInitEventList.h"

    @classmethod
    def getType(cls):
        return "host_init_event_list_t"


class event_list_intersection_t(AllenAlgorithm):
    __slots__ = OrderedDict(
        dev_event_list_a_t=GaudiDataHandle("dev_event_list_a_t", "R",
                                                "unsigned int"),
        dev_event_list_b_t=GaudiDataHandle("dev_event_list_b_t", "R",
                                                "unsigned int"),
        host_event_list_a_t=GaudiDataHandle("host_event_list_a_t", "W",
                                                 "unsigned int"),
        host_event_list_b_t=GaudiDataHandle("host_event_list_b_t", "W",
                                                 "unsigned int"),
        host_event_list_output_t=GaudiDataHandle(
            "host_event_list_output_t", "W", "unsigned int"),
        dev_event_list_output_t=GaudiDataHandle("dev_event_list_output_t",
                                                     "W", "mask_t"),
        verbosity="")
    aggregates = ()

    @staticmethod
    def category():
        return AlgorithmCategory.HostAlgorithm

    def __new__(self, name, **kwargs):
        instance = AllenAlgorithm.__new__(self, name)
        for n, v in kwargs.items():
            setattr(instance, n, v)
        return instance

    @classmethod
    def namespace(cls):
        return "event_list_intersection"

    @classmethod
    def filename(cls):
        return "/home/nn/Allen/host/combiners/include/EventListIntersection.cuh"

    @classmethod
    def getType(cls):
        return "event_list_intersection_t"


class event_list_union_t(AllenAlgorithm):
    __slots__ = OrderedDict(
        dev_event_list_a_t=GaudiDataHandle("dev_event_list_a_t", "R",
                                                "unsigned int"),
        dev_event_list_b_t=GaudiDataHandle("dev_event_list_b_t", "R",
                                                "unsigned int"),
        host_event_list_a_t=GaudiDataHandle("host_event_list_a_t", "W",
                                                 "unsigned int"),
        host_event_list_b_t=GaudiDataHandle("host_event_list_b_t", "W",
                                                 "unsigned int"),
        host_event_list_output_t=GaudiDataHandle(
            "host_event_list_output_t", "W", "unsigned int"),
        dev_event_list_output_t=GaudiDataHandle("dev_event_list_output_t",
                                                     "W", "mask_t"),
        verbosity="")
    aggregates = ()

    @staticmethod
    def category():
        return AlgorithmCategory.HostAlgorithm

    def __new__(self, name, **kwargs):
        instance = AllenAlgorithm.__new__(self, name)
        for n, v in kwargs.items():
            setattr(instance, n, v)
        return instance

    @classmethod
    def namespace(cls):
        return "event_list_union"

    @classmethod
    def filename(cls):
        return "/home/nn/Allen/host/combiners/include/EventListUnion.cuh"

    @classmethod
    def getType(cls):
        return "event_list_union_t"


class event_list_inversion_t(AllenAlgorithm):
    __slots__ = OrderedDict(
        dev_event_list_input_t=GaudiDataHandle("dev_event_list_input_t",
                                                    "R", "unsigned int"),
        host_event_list_t=GaudiDataHandle("host_event_list_t", "W",
                                               "unsigned int"),
        host_event_list_output_t=GaudiDataHandle(
            "host_event_list_output_t", "W", "unsigned int"),
        dev_event_list_output_t=GaudiDataHandle("dev_event_list_output_t",
                                                     "W", "mask_t"),
        verbosity="")
    aggregates = ()

    @staticmethod
    def category():
        return AlgorithmCategory.HostAlgorithm

    def __new__(self, name, **kwargs):
        instance = AllenAlgorithm.__new__(self, name)
        for n, v in kwargs.items():
            setattr(instance, n, v)
        return instance

    @classmethod
    def namespace(cls):
        return "event_list_inversion"

    @classmethod
    def filename(cls):
        return "/home/nn/Allen/host/combiners/include/EventListInversion.cuh"

    @classmethod
    def getType(cls):
        return "event_list_inversion_t"


class generic_algorithm_t(AllenAlgorithm):
    __slots__ = OrderedDict()
    aggregates = ()

    @staticmethod
    def category():
        return AlgorithmCategory.HostAlgorithm

    def __new__(self, name, **kwargs):
        instance = AllenAlgorithm.__new__(self, name)
        for n, v in kwargs.items():
            setattr(instance, n, v)
        return instance

    @classmethod
    def namespace(cls):
        return ""

    @classmethod
    def filename(cls):
        return ""

    @classmethod
    def getType(cls):
        return "generic_algorithm_t"


class producer_1_t(generic_algorithm_t):
    __slots__ = OrderedDict(
        a_t=GaudiDataHandle("a_t", "W", "int"), conf="")

    @classmethod
    def getType(cls):
        return "producer_1_t"


class producer_2_t(generic_algorithm_t):
    __slots__ = OrderedDict(
        a_t=GaudiDataHandle("a_t", "W", "int"),
        b_t=GaudiDataHandle("b_t", "W", "int"),
        conf="")

    @classmethod
    def getType(cls):
        return "producer_2_t"


class consumer_1_t(generic_algorithm_t):
    __slots__ = OrderedDict(
        a_t=GaudiDataHandle("a_t", "R", "int"), conf="")

    @classmethod
    def getType(cls):
        return "consumer_1_t"


class consumer_2_t(generic_algorithm_t):
    __slots__ = OrderedDict(
        a_t=GaudiDataHandle("a_t", "R", "int"),
        b_t=GaudiDataHandle("b_t", "R", "int"),
        conf="")

    @classmethod
    def getType(cls):
        return "consumer_2_t"


class decider_1_t(generic_algorithm_t):
    __slots__ = OrderedDict(
        a_t=GaudiDataHandle("a_t", "W", "mask_t"), conf="")

    @classmethod
    def getType(cls):
        return "decider_1_t"


def algorithms_with_aggregates():
    return []
