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
import os
import json
from Configurables import ApplicationMgr, AllenUpdater
from PyConf import configurable
from PyConf.control_flow import CompositeNode, NodeLogic
from PyConf.Algorithms import (
    AllenTESProducer, DumpBeamline, DumpCaloGeometry, DumpMagneticField,
    DumpVPGeometry, DumpFTGeometry, DumpUTGeometry, DumpUTLookupTables,
    DumpMuonGeometry, DumpMuonTable, AllenODINProducer)
from DDDB.CheckDD4Hep import UseDD4Hep


@configurable
def allen_non_event_data_config(dump_geometry=False, out_dir="geometry"):
    return dump_geometry, out_dir


def allen_odin():
    return AllenODINProducer().ODIN


def configured_bank_types(json_filename):
    _, sequence_json = allen_json_sequence(None, json_filename)
    bank_types = set()
    with open(sequence_json) as json_file:
        j = json.load(json_file)
        for k, v in j.items():
            if 'bank_type' in v:
                bank_types.add(v['bank_type'])
    return bank_types


@configurable
def allen_json_sequence(sequence="hlt1_pp_default", json=None):
    """Provide the name of the Allen sequence and the json configuration file

    Args:
        sequence (string): name of the Allen sequence to run
        json: (string): path the JSON file to be used to configure the chosen Allen sequence. If `None`, a default file that corresponds to the sequence will be used.
    """
    if sequence is None and json is not None:
        sequence = os.path.splitext(os.path.basename(json))[0]

    config_path = "${ALLEN_INSTALL_DIR}/constants"
    json_dir = os.path.join(
        os.path.expandvars('${ALLEN_INSTALL_DIR}'), 'constants')
    available_sequences = [
        os.path.splitext(json_file)[0] for json_file in os.listdir(json_dir)
    ]
    if sequence not in available_sequences:
        raise AttributeError("Sequence {} was not built in to Allen;"
                             "available sequences: {}".format(
                                 sequence, ' '.join(available_sequences)))
    if json is None:
        json = os.path.join(config_path, "{}.json".format(sequence))
    return (sequence, json)


def setup_allen_non_event_data_service(allen_event_loop=False,
                                       bank_types=None):
    """Setup Allen non-event data

    An ExtSvc is added to the ApplicationMgr to provide the Allen non-event
    data (geometries etc.)
    """
    if type(bank_types) == list:
        bank_types = set(bank_types)

    dump_geometry, out_dir = allen_non_event_data_config()

    appMgr = ApplicationMgr()
    if not UseDD4Hep:
        # MagneticFieldSvc is required for non-DD4hep builds
        appMgr.ExtSvc.append("MagneticFieldSvc")

    appMgr.ExtSvc.extend(AllenUpdater(TriggerEventLoop=allen_event_loop))

    types = [(DumpBeamline, 'beamline', {'VP', 'VPRetinaCluster'}),
             (DumpUTGeometry, 'ut_geometry', {'UT'}),
             (DumpUTLookupTables, 'ut_tables', {'UT'}),
             (DumpCaloGeometry, 'ecal_geometry', {'ECal'}),
             (DumpVPGeometry, 'velo_geometry', {'VP', 'VPRetinaCluster'}),
             (DumpMagneticField, 'polarity', set()),
             (DumpFTGeometry, 'scifi_geometry', {"FTCluster"}),
             (DumpMuonGeometry, 'muon_geometry', {"Muon"}),
             (DumpMuonTable, 'muon_tables', {"Muon"})]

    algorithm_converters = []
    algorithm_producers = []

    def use_converter(entry):
        return (bank_types is None or not entry[2]
                or bool(entry[2].intersection(bank_types)))

    if allen_event_loop:
        algorithm_converters.append(AllenODINProducer())

    for converter_type, filename, converter_banks in filter(
            use_converter, types):
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
