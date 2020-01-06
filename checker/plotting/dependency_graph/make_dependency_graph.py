#!/usr/bin/python3

from graphviz import Digraph
from all_deps import all_dependencies

process_background_color = "#f0f8ff"
input_background_color = "#00bfff"
output_background_color = "#ff7256"

g = Digraph('G', filename='cluster.gv')
g.attr(rankdir='LR')

previous_algorithm = "start"

for algorithm in all_dependencies:
  algorithm_name = algorithm[0]
  
  with g.subgraph(name=algorithm_name) as c:
    c.attr(style="filled", color=process_background_color, shape="rectangle")
    # c.edges(algorithm[1])

  # g.node(algorithm_name, )
  g.edge(previous_algorithm, algorithm_name)

  previous_algorithm = algorithm_name


# NOTE: the subgraph name needs to begin with 'cluster' (all lowercase)
#       so that Graphviz recognizes it as a special cluster subgraph

# with g.subgraph(name='cluster_0') as c:
#     c.attr(style='filled', color=process_background_color, rankdir='TB')
#     c.node_attr.update(style='filled', color='white')
#     c.edges([('a0', 'a1'), ('a1', 'a2'), ('a2', 'a3')])
#     c.attr(label='process #1')

# with g.subgraph(name='cluster_1') as c:
#     c.attr(color='blue')
#     c.node_attr['style'] = 'filled'
#     c.edges([('b0', 'b1'), ('b1', 'b2'), ('b2', 'b3')])
#     c.attr(label='process #2')

# g.edge('start', 'a0')
# g.edge('start', 'b0')
# g.edge('a1', 'b3')
# g.edge('b2', 'a3')
# g.edge('a3', 'a0')
# g.edge('a3', 'end')
# g.edge('b3', 'end')

# g.node('start', shape='Mdiamond')
# g.node('end', shape='Msquare')

g.view()