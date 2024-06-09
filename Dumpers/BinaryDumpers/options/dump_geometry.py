###############################################################################
# (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from AllenCore.gaudi_allen_generator import make_transposed_raw_banks
from Allen.config import allen_non_event_data_config, run_allen_reconstruction
from PyConf.application import ApplicationOptions
from PyConf.application import make_odin
from PyConf.control_flow import CompositeNode, NodeLogic

options = ApplicationOptions(_enabled=False)
options.geometry_version = 'run3/before-rich1-geom-update-26052022'
options.evt_max = 1


# run_allen_reconstruction will setup all device converters by
# default, so we only need a single algorithm here to have something
# to configure
def odin_node():
    odin = make_odin()

    return CompositeNode(
        "dump_geometry", [odin],
        combine_logic=NodeLogic.NONLAZY_OR,
        force_order=True)


with allen_non_event_data_config.bind(dump_geometry=True, out_dir="geometry"):
    run_allen_reconstruction(options, odin_node)
