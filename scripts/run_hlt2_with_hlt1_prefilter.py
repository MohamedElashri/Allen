###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from Moore import options
from RecoConf.global_tools import stateProvider_with_simplified_geom
from Hlt2Conf.lines import all_lines
from RecoConf.reconstruction_objects import reconstruction
from AllenConf.HLT1 import setup_hlt1_node
from PyConf.components import Algorithm
from PyConf.control_flow import CompositeNode
from Moore.config import moore_control_flow
from AllenConf.velo_reconstruction import decode_velo
from AllenCore.generator import make_transposed_raw_banks
import itertools

# Following 2 lines needed to create cache for streaming HDRFilters
options.output_file = "hlt2_pp_default.dst"
options.output_type = "ROOT"
options.evt_max = 10

# set input / tags
options.set_input_from_testfiledb('upgrade_DC19_01_MinBiasMD')
options.set_conds_from_testfiledb('upgrade_DC19_01_MinBiasMD')
# set param dir in provideconstants to match conditions

from Allen.config import setup_allen_non_event_data_service
from PyConf.application import configure_input, configure


def make_lines():
    return [builder() for builder in all_lines.values()]


public_tools = [stateProvider_with_simplified_geom()]

config = configure_input(options)
with reconstruction.bind(from_file=False):
    # Then create the data (and control) flow for all streams.
    streams = (make_lines or options.lines_maker)()

# Create default streams definition if make_streams returned a list
if not isinstance(streams, dict):
    streams = dict(default=streams)
lines = list(itertools.chain(*streams.values()))
# Combine all lines and output in a global control flow.
top_cf_node, barriers = moore_control_flow(options, streams, 'hlt2', False)

#allen stuff -------------------------
setup_allen_non_event_data_service()

with decode_velo.bind(retina_decoding=False), make_transposed_raw_banks.bind(
        rawbank_list=[
            "ODIN", "Muon", "FTCluster", "UT", "VP", "EcalPacked", "HcalPacked"
        ]):
    hlt1_node = setup_hlt1_node()


def gather_leafs(node):
    """
    gathers algs from a tree that do decision making
    """

    def impl(node):
        if isinstance(node, Algorithm):
            yield node
        if isinstance(node, CompositeNode):
            for child in node.children:
                yield from impl(child)

    return frozenset(impl(node))


def gather_algs(node):
    return frozenset([
        alg for leaf in gather_leafs(node) for alg in leaf.all_producers(False)
    ])


def get_barriers(node):
    algs = gather_algs(node)
    barriers = []
    for alg in algs:
        props = alg.type.getDefaultProperties()
        if props.get("hasOptionals"):
            barriers += [alg]
    return barriers


# add allen to processing, before everything else
# this means that all the other stuff (hlt2) will only run if the hlt1 node passes
top_cf_node.children = (hlt1_node, ) + top_cf_node.children
# end of allen stuff ---------------------------------

config.update(
    configure(
        options,
        top_cf_node,
        public_tools=public_tools,
        barrier_algorithms=barriers + get_barriers(hlt1_node)))
