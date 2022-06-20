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
from Configurables import ApplicationMgr,  AllenUpdater
from PyConf import configurable
from PyConf.control_flow import CompositeNode, NodeLogic
from PyConf.Algorithms import (AllenTESProducer, DumpBeamline,
                               DumpUTGeometry, DumpUTLookupTables,
                               DumpCaloGeometry, DumpMagneticField,
                               DumpVPGeometry, DumpFTGeometry, 
                               DumpMuonGeometry, DumpMuonTable)
from DDDB.CheckDD4Hep import UseDD4Hep


@configurable
def allen_non_event_data_config(dump_geometry=False, out_dir="geometry"):
    return dump_geometry, out_dir


def setup_allen_non_event_data_service(allen_event_loop=False):
    """Setup Allen non-event data

    An ExtSvc is added to the ApplicationMgr to provide the Allen non-event
    data (geometries etc.)
    """
    dump_geometry, out_dir = allen_non_event_data_config()

    appMgr = ApplicationMgr()
    if not UseDD4Hep:
        # MagneticFieldSvc is required for non-DD4hep builds
        appMgr.ExtSvc.append("MagneticFieldSvc")

    appMgr.ExtSvc.extend(AllenUpdater(TriggerEventLoop=allen_event_loop))

    types = [(DumpBeamline, 'beamline'), 
             (DumpCaloGeometry, 'ecal_geometry'),
             (DumpUTGeometry, 'ut_geometry'), (DumpUTLookupTables, 'ut_tables'),
             (DumpVPGeometry, 'velo_geometry'), 
             (DumpMagneticField, 'polarity'),
             #(DumpFTGeometry, 'scifi_geometry'),
             (DumpMuonGeometry, 'muon_geometry'), (DumpMuonTable, 'muon_tables')]

    algorithm_converters = []
    algorithm_producers = []
    for converter_type, filename in types:
        converter_id = converter_type.getDefaultProperties().get('ID', None)
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
        algorithm_converters.append(converter)

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
