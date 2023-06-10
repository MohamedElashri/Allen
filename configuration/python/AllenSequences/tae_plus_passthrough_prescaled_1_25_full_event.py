###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
from PyConf.control_flow import NodeLogic, CompositeNode
from AllenCore.generator import generate, make_algorithm
from AllenConf.hlt1_calibration_lines import make_passthrough_line
from AllenConf.persistency import make_global_decision, make_routingbits_writer
from AllenConf.odin import decode_odin, make_bxtype, odin_error_filter, tae_filter
from AllenCore.algorithms import data_provider_t
from AllenConf.utils import line_maker
from AllenConf.validators import rate_validation

bank_providers = [decode_odin()['dev_odin_data'].producer]
lines = []
# To test memory traffic when copying to the device, add the following
for det, bt in (("velo", "VP"), ("scifi", "FTCluster"), ("muon", "Muon"),
                ("ecal_banks", "ECal")):
    bank_providers.append(
        make_algorithm(data_provider_t, name=det + "_banks", bank_type=bt))

passthrough_line = line_maker(make_passthrough_line(pre_scaler=0.04))
lines.append(passthrough_line)

prefilters = [odin_error_filter("odin_error_filter")]
with line_maker.bind(
        prefilter=prefilters + [tae_filter(accept_sub_events=False)]):
    lines.append(
        line_maker(
            make_passthrough_line(name="Hlt1TAEPassthrough", pre_scaler=1)))

line_algorithms = [tup[0] for tup in lines]

global_decision = make_global_decision(lines=line_algorithms)

providers = CompositeNode(
    "Providers", bank_providers, NodeLogic.NONLAZY_AND, force_order=False)

lines = CompositeNode(
    "AllLines", [tup[1] for tup in lines],
    NodeLogic.NONLAZY_OR,
    force_order=False)

passthrough_sequence = CompositeNode(
    "Passthrough", [
        providers, lines,
        make_routingbits_writer(lines=line_algorithms), global_decision,
        rate_validation(lines=line_algorithms)
    ],
    NodeLogic.NONLAZY_AND,
    force_order=True)

generate(passthrough_sequence)
