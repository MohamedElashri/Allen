###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
from Configurables import ApplicationMgr, AllenUpdater
from PyConf import configurable
from PyConf.control_flow import CompositeNode, NodeLogic
from PyConf.Algorithms import (
    AllenTESProducer, DumpBeamline, DumpCaloGeometry, DumpMagneticField,
    DumpVPGeometry, DumpFTGeometry, DumpUTGeometry, DumpUTLookupTables,
    DumpMuonGeometry, DumpMuonTable)
from DDDB.CheckDD4Hep import UseDD4Hep

import os
import json as json_module


@configurable
def allen_non_event_data_config(dump_geometry=False, out_dir="geometry"):
    return dump_geometry, out_dir


def allen_configure_producers(sequence_name):
    type_mapping = {
        'VP': [(DumpBeamline, 'beamline'), (DumpVPGeometry, 'velo_geometry')],
        'UT': [(DumpUTGeometry, 'ut_geometry'),
               (DumpUTLookupTables, 'ut_tables')],
        'ECal': [(DumpCaloGeometry, 'ecal_geometry')],
        'FT': [(DumpFTGeometry, 'scifi_geometry')],
        'Muon': [(DumpMuonGeometry, 'muon_geometry'),
                 (DumpMuonTable, 'muon_tables')],
        'magnetic_field': [(DumpMagneticField, 'polarity')]
    }

    requested_banks = {}

    json = "$ALLEN_INSTALL_DIR/constants/" + sequence_name + ".json"

    with open(os.path.expandvars(json), 'r') as f:
        j = json_module.load(f)
    for algo in j["sequence"]["configured_algorithms"]:
        if algo[2] == "ProviderAlgorithm":
            #print("algo: " + algo[1] + ", bank type = " + j[algo[1]]["bank_type"])
            requested_banks[j[algo[1]]["bank_type"]] = True

    requested_banks['magnetic_field'] = True  # always dump magnetic field

    dump_geometry, out_dir = allen_non_event_data_config()

    algorithm_converters = []
    algorithm_producers = []
    for key, types in type_mapping.items():
        if key in requested_banks.keys():
            print("Adding producers for bank type: " + key)
            for converter_type, filename in types:
                converter_id = converter_type.getDefaultProperties().get(
                    'ID', None)
                if converter_id is not None:
                    converter = converter_type()
                    # An algorithm that needs a TESProducer
                    producer = AllenTESProducer(
                        Filename=filename if dump_geometry else "",
                        OutputDirectory=out_dir,
                        InputID=converter.OutputID,
                        InputData=converter.Converted,
                        ID=converter_id)
                    algorithm_producers.append(producer)
                else:
                    converter = converter_type(
                        DumpToFile=dump_geometry, OutputDirectory=out_dir)
                print("Adding producer algorithm: " + str(converter))
            algorithm_converters.append(converter)
            if not types:
                print(
                    "ERROR: No converter algorithm registered as producer for bank type "
                    + key)

    return [algorithm_converters, algorithm_producers, requested_banks]


def setup_allen_non_event_data_service(allen_event_loop=False,
                                       sequence_name="hlt1_pp_default"):
    """Setup Allen non-event data

    An ExtSvc is added to the ApplicationMgr to provide the Allen non-event
    data (geometries etc.)
    """
    dump_geometry, out_dir = allen_non_event_data_config()
    appMgr = ApplicationMgr()
    if not UseDD4Hep:
        # MagneticFieldSvc is required for non-DD4hep builds
        appMgr.ExtSvc.append("MagneticFieldSvc")

    algorithm_converters, algorithm_producers, requested_banks = allen_configure_producers(
        sequence_name)

    appMgr.ExtSvc.extend(
        AllenUpdater(
            TriggerEventLoop=allen_event_loop,
            RequestedBanks=list(requested_banks.keys())))

    converters_node = CompositeNode(
        "allen_non_event_data_converters",
        algorithm_converters,
        combine_logic=NodeLogic.NONLAZY_OR,
        force_order=True)
    producers_node = CompositeNode(
        "allen_non_event_data_producers",
        algorithm_producers,
        combine_logic=NodeLogic.NONLAZY_OR,
        force_order=True)

    control_flow = [converters_node, producers_node]
    cf_node = CompositeNode(
        "allen_non_event_data",
        control_flow,
        combine_logic=NodeLogic.LAZY_AND,
        force_order=True)

    return cf_node
