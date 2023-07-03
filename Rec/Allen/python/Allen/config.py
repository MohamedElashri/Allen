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
from collections import OrderedDict
from PyConf import configurable
from PyConf.control_flow import CompositeNode, NodeLogic
from PyConf.application import all_nodes_and_algs
from PyConf.application import configure_input, configure
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


@configurable
def allen_json_sequence(sequence="hlt1_pp_default", json=None):
    """Provide the name of the Allen sequence and the json configuration file

    Args:
        sequence (string): name of the Allen sequence to run
        json: (string): path the JSON file to be used to configure the chosen Allen sequence. If `None`, a default file that corresponds to the sequence will be used.
    """
    if sequence is None and json is not None:
        sequence = os.path.splitext(os.path.basename(json))[0]

    if json is None:
        config_path = "${ALLEN_INSTALL_DIR}/constants"
        json_dir = os.path.join(
            os.path.expandvars('${ALLEN_INSTALL_DIR}'), 'constants')
        available_sequences = [
            os.path.splitext(json_file)[0]
            for json_file in os.listdir(json_dir)
        ]
        if sequence not in available_sequences:
            raise AttributeError("Sequence {} was not built in to Allen;"
                                 "available sequences: {}".format(
                                     sequence, ' '.join(available_sequences)))
        json = os.path.join(config_path, "{}.json".format(sequence))
    elif not os.path.exists(json):
        raise OSError("JSON file does not exist")

    return (sequence, json)


def allen_detectors(allen_node):
    # Rather hacky, but there is currently no other way to figure out
    # which bank types are needed, and thus which geometry providers
    # should be added. This can be removed once the UT initializes
    # with DD4hep
    nodes, algs = all_nodes_and_algs(allen_node)
    config = OrderedDict()
    for alg in algs:
        config.update(alg.configuration())

    bank_types = chain.from_iterable([
        v['BankTypes'] for k, v in config.items()
        if k[0].getType() == 'TransposeRawBanks'
    ])
    bank_types = set(bank_types)
    bank_types.discard('ODIN')

    def _swap(bt, other):
        if bt in bank_types:
            bank_types.remove(bt)
            bank_types.add(other)

    for bt, other in [('Calo', 'ECal'), ('EcalPacked', 'ECal')]:
        _swap(bt, other)

    return bank_types


def configured_bank_types(sequence_json):
    sequence_json = json.loads(sequence_json)
    bank_types = set()
    for t, n, c in sequence_json["sequence"]["configured_algorithms"]:
        props = sequence_json.get(n, {})
        if c == "ProviderAlgorithm" and not bool(props.get('empty', False)):
            bank_types.add(props['bank_type'])
    return bank_types


def setup_allen_non_event_data_service(allen_event_loop=False,
                                       bank_types=None):
    """Setup Allen non-event data

    An ExtSvc is added to the ApplicationMgr to provide the Allen non-event
    data (geometries etc.)
    """
    converter_types = {
        'VP': [(DumpBeamline, 'DumpBeamline', 'beamline'),
               (DumpVPGeometry, 'DumpVPGeometry', 'velo_geometry')],
        'UT': [(DumpUTGeometry, 'DumpUTGeometry', 'ut_geometry'),
               (DumpUTLookupTables, 'DumpUTLookupTables', 'ut_tables')],
        'ECal': [(DumpCaloGeometry, 'DumpCaloGeometry', 'ecal_geometry')],
        'Magnet': [(DumpMagneticField, 'DumpMagneticField', 'polarity')],
        'FTCluster': [(DumpFTGeometry, 'DumpFTGeometry', 'scifi_geometry')],
        'Muon': [(DumpMuonGeometry, 'DumpMuonGeometry', 'muon_geometry'),
                 (DumpMuonTable, 'DumpMuonTable', 'muon_tables')]
    }

    detector_names = {
        'ECal': 'Ecal',
        'FTCluster': 'FT',
        'PVs': None,
        'tracks': None,
        'Plume': None,
    }

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
        DD4hepSvc().DetectorList = ["/world"] + list(
            filter(lambda d: d is not None,
                   [detector_names.get(det, det) for det in bank_types]))

    data_bank_types = bank_types.copy()
    data_bank_types.remove('Magnet')
    appMgr.ExtSvc.extend(
        AllenUpdater(
            TriggerEventLoop=allen_event_loop,
            BankTypes=list(data_bank_types)))

    algorithm_converters = []
    algorithm_producers = []

    if allen_event_loop:
        algorithm_converters.append(AllenODINProducer())

    converters = [(bt, t, tn, f) for bt, convs in converter_types.items()
                  for t, tn, f in convs if bt in bank_types]
    for bt, converter_type, converter_name, filename in converters:
        converter_id = converter_type.getDefaultProperties().get('ID', None)
        if converter_id is not None:
            converter = converter_type()
            # An algorithm that needs a TESProducer
            producer = AllenTESProducer(
                name='AllenTESProducer_%s' % bt,
                Filename=filename if dump_geometry else "",
                OutputDirectory=out_dir,
                InputID=converter.OutputID,
                InputData=converter.Converted,
                ID=converter_id)
            algorithm_producers.append(producer)
        else:
            converter = converter_type(
                name=converter_name,
                DumpToFile=dump_geometry,
                OutputDirectory=out_dir)
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


def run_allen_reconstruction(options, make_reconstruction, public_tools=[]):
    """Configure the Allen reconstruction data flow

    Convenience function that configures all services and creates a data flow.

    Args:
        options (ApplicationOptions): holder of application options
        make_reconstruction: function returning a single CompositeNode object
        public_tools (list): list of public `Tool` instances to configure

    """
    from Allen.config import setup_allen_non_event_data_service

    config = configure_input(options)

    reconstruction = make_reconstruction()
    reco_node = reconstruction if not hasattr(reconstruction,
                                              "node") else reconstruction.node

    detectors = allen_detectors(reco_node)
    non_event_data_node = setup_allen_non_event_data_service(
        bank_types=detectors)

    allen_node = CompositeNode(
        'allen_reconstruction',
        combine_logic=NodeLogic.NONLAZY_OR,
        children=[non_event_data_node, reco_node],
        force_order=True)

    config.update(configure(options, allen_node, public_tools=public_tools))
    return config
