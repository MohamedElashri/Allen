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
from itertools import chain
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
        for t, n, c in j["sequence"]["configured_algorithms"]:
            props = j.get(n, {})
            if c == "ProviderAlgorithm" and not bool(
                    props.get('empty', False)):
                bank_types.add(props['bank_type'])
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
    converter_types = {
        'VP': [(DumpBeamline, 'beamline'), (DumpVPGeometry, 'velo_geometry')],
        'UT': [(DumpUTGeometry, 'ut_geometry'),
               (DumpUTLookupTables, 'ut_tables')],
        'ECal': [(DumpCaloGeometry, 'ecal_geometry')],
        'Magnet': [(DumpMagneticField, 'polarity')],
        'FTCluster': [(DumpFTGeometry, 'scifi_geometry')],
        'Muon': [(DumpMuonGeometry, 'muon_geometry'),
                 (DumpMuonTable, 'muon_tables')]
    }

    detector_names = {'ECal': 'Ecal', 'FTCluster': 'FT',
                      'PVs': None, 'tracks': None}

    if type(bank_types) == list:
        bank_types = set(bank_types)
    elif bank_types is None:
        bank_types = set(converter_types.keys())

    if 'VPRetinaCluster' in bank_types:
        bank_types.remove('VPRetinaCluster')
        bank_types.add('VP')

    # Always include the magnetic field polarity
    bank_types.add('Magnet')

    dump_geometry, out_dir = allen_non_event_data_config()

    appMgr = ApplicationMgr()
    if not UseDD4Hep:
        # MagneticFieldSvc is required for non-DD4hep builds
        appMgr.ExtSvc.append("MagneticFieldSvc")
    else:
        # Configure those detectors that we need
        from Configurables import LHCb__Det__LbDD4hep__DD4hepSvc as DD4hepSvc
        DD4hepSvc().DetectorList = ["/world"] + list(filter(lambda d: d is not None, [
            detector_names.get(det, det) for det in bank_types
        ]))

    appMgr.ExtSvc.extend(AllenUpdater(TriggerEventLoop=allen_event_loop))

    algorithm_converters = []
    algorithm_producers = []

    if allen_event_loop:
        algorithm_converters.append(AllenODINProducer())

    converters = chain.from_iterable(
        convs for bt, convs in converter_types.items() if bt in bank_types)
    for converter_type, filename in converters:
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
