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
from AllenCore.gaudi_allen_generator import make_transposed_raw_banks
from Allen.config import allen_non_event_data_config, run_allen_reconstruction
from PyConf.application import ApplicationOptions
from PyConf.application import configure_input, configure
from PyConf.tonic import configurable
from PyConf.control_flow import CompositeNode, NodeLogic
from DDDB.CheckDD4Hep import UseDD4Hep

options = ApplicationOptions(_enabled=False)
options.evt_max = 1


@configurable
def dump_geometry(with_ut=None):
    subdetectors = [
        "VPRetinaCluster", "FTCluster", "Muon", "ODIN", "Calo", "EcalPacked"
    ]
    if with_ut is None:
        with_ut = not UseDD4Hep
    if with_ut:
        subdetectors += ["UT"]
    allen_banks = make_transposed_raw_banks(subdetectors)

    return CompositeNode(
        "dump_geometry", [allen_banks],
        combine_logic=NodeLogic.NONLAZY_OR,
        force_order=True)


with (allen_non_event_data_config.bind(dump_geometry=True, out_dir="geometry"),
      dump_geometry.bind(with_ut=False)):
    run_allen_reconstruction(options, dump_geometry)
