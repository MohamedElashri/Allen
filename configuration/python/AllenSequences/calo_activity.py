###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_global_decision
from AllenConf.odin import decode_odin
from AllenConf.algorithms import data_provider_t
from AllenConf.HLT1 import line_maker
from AllenConf.validators import rate_validation
from AllenConf.calo_reconstruction import decode_calo
from AllenConf.algorithms import calo_decode_t, calo_count_digits_t
from AllenConf.utils import initialize_number_of_events 
from AllenConf.algorithms import host_prefix_sum_t
from AllenConf.hlt1_monitoring_lines import make_calo_digits_minADC_line

odin_provider = decode_odin()['dev_odin_raw_input'].producer

calo_provider = decode_calo()['dev_ecal_digits'].producer
#bank_providers.append([decode_calo()['dev_ecal_digits'].producer])

passthrough_line = line_maker(
    "Hlt1Passthrough",
    make_passthrough_line(
        name="Hlt1Passthrough",
        pre_scaler_hash_string="passthrough_line_pre",
        post_scaler_hash_string="passthrough_line_post"),
    enableGEC=False)

calo_digits_line = line_maker(
    "Hlt1CaloDigitsMinADC",
    make_calo_digits_minADC_line(decode_calo()),
    enableGEC=False)


line_algorithms = [calo_digits_line[0]] 

global_decision = make_global_decision(lines=line_algorithms)

providers = CompositeNode(
    "Providers", [calo_provider], NodeLogic.NONLAZY_AND, force_order=False)

lines = CompositeNode(
    "AllLines", [calo_digits_line[1]], NodeLogic.NONLAZY_OR, force_order=False)

passthrough_sequence = CompositeNode(
        "Passthrough", [
            #providers,
            lines,
            global_decision,
            rate_validation(lines=line_algorithms)
        ],
        NodeLogic.NONLAZY_AND,
        force_order=True)

generate(passthrough_sequence)
