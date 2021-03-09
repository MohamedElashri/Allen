###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from definitions.HLT1 import setup_hlt1_node
from definitions.event_list_utils import generate

hlt1_node = setup_hlt1_node()
generate(hlt1_node)

# # Generate a pydot graph out of the configuration
# from pydot import Graph
# y = Graph()
# hlt1_node._graph(y)
# with open('blub.dot', 'w') as f:
#     f.write(y.to_string())
