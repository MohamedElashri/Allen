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
from AllenConf.downstream_reconstruction import make_downstream_objects

from AllenConf.validators import dump_downstream_secondary_vertices
from AllenConf.filters import make_gec
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate

downstream = make_downstream_objects()
downstream_tracks = downstream['downstream_tracks']
downstream_secondary_vertices = downstream['downstream_secondary_vertices']

dump_downstream_svs = dump_downstream_secondary_vertices(
    downstream_tracks=downstream_tracks,
    downstream_secondary_vertices=downstream_secondary_vertices,
    name="DumpDownstreamSVs")

downstream_sequence = CompositeNode(
    "DumpDownstreamSVsSequence", [dump_downstream_svs],
    NodeLogic.LAZY_AND,
    force_order=True)
generate(downstream_sequence)

# downstream_make_secondary_vertices
