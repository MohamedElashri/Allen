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

try:
    from html import escape as html_escape
except ImportError:
    from cgi import escape as html_escape

from enum import Enum
import pydot

from .components import Algorithm
from .dataflow import DataHandle, get_dependencies

__all__ = [
    "NodeLogic",
    "CompositeNode",
]


# FIXME not sure if i want to have this or rather just strings
class NodeLogic(Enum):
    """Node control flow behaviour.

    Each node contains an ordered set of subnodes/child nodes. These are
    processed in order one by one until the node can return True or False.
    Whether a node can return depends on its control flow behaviour.
    """

    AND = "&"
    OR = "|"
    NOT = "~"


class Leaf(object):
    leafs = dict()

    def __new__(cls, name: str, execution_weight=1, average_eff=1, alg=None):
        instance = super(cls, Leaf).__new__(cls)
        instance._name = name
        instance._execution_weight = execution_weight
        instance._average_eff = average_eff
        instance._dependencies = [] if not alg else get_dependencies(alg) + [alg]
        instance._id = instance._calc_id()
        if instance._name in cls.leafs:
            assert (
                cls.leafs[instance._name]._id == instance._id
            ), f"A leaf with the name '{name}', but different properties already exists. Exiting.."
            return cls.leafs[instance._name]
        cls.leafs[instance._name] = instance
        return instance

    @property
    def execution_weight(self):
        return self._execution_weight

    @property
    def average_eff(self):
        return self._average_eff

    def __repr__(self):
        return f"{self._name}"

    @property
    def name(self):
        return self._name

    @property
    def algs(self):
        return self._dependencies

    def _calc_id(self):
        return hash(
            f"{self._execution_weight},{self._average_eff},{[hash(alg) for alg in self.algs]}"
        )

    def __hash__(self):
        return self._id

    def __eq__(self, other):
        return hash(self) == hash(other)


class CompositeNode(object):
    """A container for a set of subnodes/child nodes."""

    def __init__(self, name, combineLogic, children, lazy=True, forceOrder=False):
        if not isinstance(combineLogic, NodeLogic):
            raise TypeError("combineLogic must take an instance of NodeLogic")
        self.name = name
        # TODO we need some type checking below for the children
        from ast import Name, BinOp, UnaryOp

        assert all(
            [
                isinstance(c, Leaf)
                or isinstance(c, CompositeNode)
                or isinstance(c, Name)
                or isinstance(c, BinOp)
                or isinstance(c, UnaryOp)
                for c in children
            ]
        ), f"composite with child of type {[type(c) for c in children]} is not supported"
        if combineLogic == NodeLogic.NOT:
            assert(len(children) == 1)
        self.children = children
        self.combineLogic = combineLogic
        self.lazy = lazy
        self.forceOrder = forceOrder
        self._id = hash(f"{self.combineLogic},{self.lazy},{[hash(child) for child in self.children]}")

    def __eq__(self, other):  # TODO maybe not needed
        if not isinstance(other, CompositeNode):
            return False
        return hash(self) == hash(other)

    @property  # for API compatibility with Algorithm
    def fullname(self):
        return self.name

    @property
    def is_lazy(self):
        return self.lazy

    @property
    def is_ordered(self):
        return self.forceOrder

    @property
    def logic(self):
        return self.combineLogic

    def represent(self):
        return (
            self.name,
            self.combineLogic.value,
            [c.fullname for c in self.children],
            self.forceOrder,
        )

    def __repr__(self):
        from .cftree_ops import to_string
        return to_string(self)

    def __hash__(self):
        return self._id

    def __eq__(self, other):
        return hash(self) == hash(other)

    def _graph(self, graph):
        own_name = html_escape(self.name)
        sg = pydot.Subgraph(graph_name='cluster_' + own_name)

        label = ('<<B>{}</B><BR/>{}, {}>'.format(
            own_name,
            str(self.combineLogic).replace('NodeLogic.', ''),
            'ordered' if self.forceOrder else 'unordered'))
        sg.set_label(label)
        sg.set_edge_defaults(dir='forward' if self.forceOrder else 'none')

        node = prev_node = None
        for child in self.children:
            if isinstance(child, Leaf):
                # Must name nodes uniquely within a node, otherwise they will
                # only be drawn one (which makes sense for the *data* flow!)
                node = pydot.Node(
                    html_escape('{}_{}'.format(self.name, child.name)),
                    label=child.name)
                sg.add_node(node)
            else:
                node = child._graph(sg)

            if prev_node is not None:
                # When drawing edges to/from subgraphs, the target node must be
                # a node inside the subgraph, which we take as the first.
                # However we want the arrow to start/from from the edge of the
                # subgraph, so must set the ltail/lhead attribute appropriately
                if isinstance(prev_node, pydot.Subgraph):
                    tail_node = _find_first_node(prev_node)
                    ltail = prev_node.get_name()
                else:
                    tail_node = prev_node
                    ltail = None
                if isinstance(node, pydot.Subgraph):
                    head_node = _find_first_node(node)
                    lhead = node.get_name()
                else:
                    head_node = node
                    lhead = None
                edge = pydot.Edge(tail_node, head_node)
                if ltail is not None:
                    edge.set_ltail(ltail)
                if lhead is not None:
                    edge.set_lhead(lhead)
                sg.add_edge(edge)

            prev_node = node

        if node is None:
            node = pydot.Node('{}_empty'.format(own_name), label='Empty node')
            sg.add_node(node)

        graph.add_subgraph(sg)

        return sg


class ProduceAllNode(CompositeNode):
    """A wrapper around CompositeNode to unconditionally execute producers."""

    def __init__(self, name, data):
        super(ProduceAllNode, self).__init__(
            name, data, combineLogic=NodeLogic.OR, forceOrder=False, lazy=False
        )


def _find_first_node(node):
    """Return the first pydot.Node object found within the node tree."""
    # The 'edge' node defines edge defaults; we can't create edges to/from it
    if isinstance(node, pydot.Node) and node.get_name() != "edge":
        return node
    elif isinstance(node, pydot.Subgraph):
        # Recurse down in to the subgraph's nodes and subgraphs
        subnodes = node.get_nodes() + node.get_subgraphs()
        for subnode in filter(None, map(_find_first_node, subnodes)):
            # Return the first node we find
            return subnode

    return None
